import { cronJobs } from "convex/server";
import { internal } from "./_generated/server";

// @ts-check

/**
 * Cron jobs para ColmadoAI
 */
const crons = cronJobs();

// Cron diario: envía resumen a las 8 PM (hora de República Dominicana = UTC-4)
// 20:00 RD = 00:00 UTC
crons.daily(
  "resumen-diario-colmaderos",
  { hourUTC: 0, minuteUTC: 0 },
  internal.telegram.resumenDiario
);

export default crons;