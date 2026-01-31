// ==============================================
// Prisma Client Configuration (v7)
// ==============================================
// This file configures the Prisma Client datasource
// The database URL is read from DATABASE_URL env var
// ==============================================

export const config = {
    datasources: {
        db: {
            url: process.env.DATABASE_URL
        }
    }
};
