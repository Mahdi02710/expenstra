const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const MONTHS_WINDOW = 12;
const ANALYTICS_DOC_ID = "summary";

const toMonthKey = (date) => {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
};

const addMonths = (date, offset) => {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + offset, 1));
};

const mean = (values) => {
  if (!values.length) return 0;
  return values.reduce((sum, v) => sum + v, 0) / values.length;
};

const stdDev = (values) => {
  if (values.length < 2) return 0;
  const avg = mean(values);
  const variance =
    values.reduce((sum, v) => sum + Math.pow(v - avg, 2), 0) / values.length;
  return Math.sqrt(variance);
};

const linearRegression = (values) => {
  const n = values.length;
  if (n === 0) return { slope: 0, intercept: 0 };
  const xMean = (n - 1) / 2;
  const yMean = mean(values);

  let numerator = 0;
  let denominator = 0;
  for (let i = 0; i < n; i += 1) {
    numerator += (i - xMean) * (values[i] - yMean);
    denominator += Math.pow(i - xMean, 2);
  }

  const slope = denominator === 0 ? 0 : numerator / denominator;
  const intercept = yMean - slope * xMean;
  return { slope, intercept };
};

const round = (value, decimals = 2) => {
  const factor = Math.pow(10, decimals);
  return Math.round(value * factor) / factor;
};

exports.onTransactionWrite = functions.firestore
  .document("users/{userId}/transactions/{transactionId}")
  .onWrite(async (change, context) => {
    const { userId } = context.params;
    const db = admin.firestore();
    const userRef = db.collection("users").doc(userId);
    const analyticsRef = userRef.collection("analytics").doc(ANALYTICS_DOC_ID);

    const now = new Date();
    const windowStart = addMonths(now, -(MONTHS_WINDOW - 1));
    const windowEnd = addMonths(now, 1);

    const snapshot = await userRef
      .collection("transactions")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(windowStart))
      .where("date", "<", admin.firestore.Timestamp.fromDate(windowEnd))
      .get();

    const months = Array.from({ length: MONTHS_WINDOW }, (_, index) =>
      addMonths(windowStart, index),
    );
    const monthIndex = months.reduce((acc, month, index) => {
      acc[toMonthKey(month)] = index;
      return acc;
    }, {});

    const monthlyTotals = months.reduce((acc, month) => {
      acc[toMonthKey(month)] = 0;
      return acc;
    }, {});

    const categoryMonthly = {};
    const categoryTotals = {};

    snapshot.forEach((doc) => {
      const data = doc.data() || {};
      if (data.type !== "expense") return;
      const amount = Number(data.amount) || 0;
      if (amount <= 0) return;

      const date =
        data.date && typeof data.date.toDate === "function"
          ? data.date.toDate()
          : new Date(data.date);
      const monthKey = toMonthKey(date);
      if (monthIndex[monthKey] === undefined) return;

      monthlyTotals[monthKey] = (monthlyTotals[monthKey] || 0) + amount;

      const category = data.category || "Other";
      if (!categoryMonthly[category]) {
        categoryMonthly[category] = Array(months.length).fill(0);
      }
      categoryMonthly[category][monthIndex[monthKey]] += amount;
      categoryTotals[category] = (categoryTotals[category] || 0) + amount;
    });

    const orderedTotals = months.map((month) => monthlyTotals[toMonthKey(month)] || 0);
    const { slope, intercept } = linearRegression(orderedTotals);
    const avg = mean(orderedTotals);
    const trendPercent = avg === 0 ? 0 : (slope / avg) * 100;

    const nextMonth = addMonths(months[months.length - 1], 1);
    const nextMonthKey = toMonthKey(nextMonth);
    const seasonalSource =
      months.find((m) => m.getUTCMonth() === nextMonth.getUTCMonth()) ||
      months[months.length - 1];
    const seasonalValue = monthlyTotals[toMonthKey(seasonalSource)] || 0;
    const seasonalFactor = avg === 0 ? 1 : seasonalValue / avg;

    const prediction = intercept + slope * months.length;
    const forecast = Math.max(0, prediction * seasonalFactor);

    const insights = [];
    const lastMonthValue = orderedTotals[orderedTotals.length - 1] || 0;
    const priorValues = orderedTotals.slice(0, -1);
    const priorAvg = mean(priorValues);
    const overallStd = stdDev(orderedTotals);

    if (priorAvg > 0 && lastMonthValue > priorAvg * 1.3) {
      insights.push({
        type: "spike",
        title: "Spending spike detected",
        detail: `Last month spending was ${(lastMonthValue / priorAvg * 100).toFixed(
          0,
        )}% of your 12-month average.`,
      });
    }

    if (overallStd > 0 && lastMonthValue > avg + 1.5 * overallStd) {
      insights.push({
        type: "anomaly",
        title: "Unusual spending month",
        detail: `Last month was ${(lastMonthValue / avg * 100).toFixed(
          0,
        )}% of your average.`,
      });
    }

    const topCategoryEntry = Object.entries(categoryTotals).sort((a, b) => b[1] - a[1])[0];
    if (topCategoryEntry) {
      const [category, total] = topCategoryEntry;
      const avgMonthly = total / MONTHS_WINDOW;
      insights.push({
        type: "top_category",
        title: "Top spending category",
        detail: `${category} averages ${round(avgMonthly, 0)} per month.`,
      });
    }

    let mostVolatile = null;
    let mostVolatileStd = 0;
    Object.entries(categoryMonthly).forEach(([category, values]) => {
      const categoryStd = stdDev(values);
      if (categoryStd > mostVolatileStd) {
        mostVolatileStd = categoryStd;
        mostVolatile = category;
      }
    });
    if (mostVolatile && mostVolatileStd > 0) {
      insights.push({
        type: "volatility",
        title: "Most volatile category",
        detail: `${mostVolatile} varies the most month-to-month.`,
      });
    }

    const direction = trendPercent >= 0 ? "up" : "down";
    const seasonalNote =
      seasonalFactor === 1
        ? "Seasonality is neutral."
        : `Next month is typically ${Math.abs((seasonalFactor - 1) * 100).toFixed(
            0,
          )}% ${seasonalFactor > 1 ? "higher" : "lower"} than average.`;
    const explanation = `Spending trend is ${direction} ${Math.abs(trendPercent).toFixed(
      1,
    )}% per month. ${seasonalNote}`;

    await analyticsRef.set(
      {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        windowMonths: MONTHS_WINDOW,
        monthlyTotals: months.map((month) => ({
          month: toMonthKey(month),
          value: round(monthlyTotals[toMonthKey(month)] || 0),
        })),
        forecast: {
          nextMonth: round(forecast),
          trendPercent: round(trendPercent, 2),
          seasonalFactor: round(seasonalFactor, 2),
          explanation,
        },
        insights,
      },
      { merge: true },
    );
  });
