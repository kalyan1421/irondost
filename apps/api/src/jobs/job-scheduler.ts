export type JobHandler<T> = (data: T) => Promise<void>;

export interface ScheduleOptions {
  /** Run no earlier than this instant. Defaults to now. */
  startAfter?: Date;
}

/**
 * Background-job port. Production uses pg-boss (jobs stored in Postgres);
 * tests swap in an in-memory implementation they can drain on demand.
 */
export abstract class JobScheduler {
  abstract register<T extends object>(queue: string, handler: JobHandler<T>): void;
  abstract schedule<T extends object>(queue: string, data: T, options?: ScheduleOptions): Promise<void>;
}
