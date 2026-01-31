import createMDX from '@next/mdx';
import type { NextConfig } from 'next';

// API URL from environment (defaults to localhost:3001 for local dev)
// API URL from environment (defaults to localhost:3001 for local dev)
// Prioritize INTERNAL_API_URL for Docker container-to-container communication
const apiUrl = process.env.INTERNAL_API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

const nextConfig: NextConfig = {
    /* config options here */

    // Enable standalone output for Docker optimization
    output: 'standalone',

    reactCompiler: true,
    pageExtensions: ['js', 'jsx', 'md', 'mdx', 'ts', 'tsx'],
    // Increase server timeout for long browser operations
    serverExternalPackages: [],
    experimental: {
        proxyTimeout: 120000 // 2 minute timeout for API proxy
    },
    // Turbopack configuration for monorepo Docker builds
    turbopack: {
        root: '../' // Point to monorepo root (parent of frontend/)
    },
    // Disable response buffering for SSE
    async headers() {
        return [
            {
                source: '/api/:path*',
                headers: [
                    { key: 'X-Accel-Buffering', value: 'no' },
                    { key: 'Cache-Control', value: 'no-cache, no-transform' }
                ]
            }
        ];
    },
    async rewrites() {
        // Evaluate at runtime to support Docker container environment variables
        // Use bracket notation to avoid build-time inlining by Next.js/Webpack
        const isDocker = process.env['HOSTNAME'] === '0.0.0.0';
        const defaultUrl = isDocker ? 'http://backend:3001' : 'http://localhost:3001';
        const apiUrl = process.env['INTERNAL_API_URL'] || process.env['NEXT_PUBLIC_API_URL'] || defaultUrl;

        console.log(`Resources Proxing to Backend: ${apiUrl} (Docker: ${isDocker})`);

        return [
            {
                source: '/api/:path*',
                destination: `${apiUrl}/api/:path*`
            }
        ];
    }
};

const withMDX = createMDX({
    extension: /\.mdx$/,
    options: {
        // Use string-based plugin definition for Turbopack compatibility
        remarkPlugins: [['remark-gfm', { strict: true, throwOnError: true }]],
        rehypePlugins: []
    }
});

export default withMDX(nextConfig);
