import http from 'k6/http';
import { check, sleep } from 'k6';

// k6 Load Test Script (Section 10 of guide)
// Configured with 5 Virtual Users (VUs) for 30s duration
export const options = {
  vus: 5,
  duration: '30s',
  thresholds: {
    // Error rate must be less than 1%
    http_req_failed: ['rate<0.01'],
    // 95% of requests must complete below 500ms
    // (Exercise prompt: change threshold, e.g. p(95)<200 to test failure/success conditions)
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const baseUrl = __ENV.BASE_URL || 'http://localhost:3000';
  const response = http.get(`${baseUrl}/health`);

  check(response, {
    'health returns 200': (r) => r.status === 200,
  });

  sleep(1);
}
