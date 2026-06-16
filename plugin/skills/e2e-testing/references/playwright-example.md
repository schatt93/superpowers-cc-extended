# Playwright E2E device-matrix example (skeleton)

Real boundaries; role/label selectors; matrix via projects.

```js
// playwright.config — matrix of real viewports/browsers
projects: [
  { name: 'chromium-desktop', use: devices['Desktop Chrome'] },
  { name: 'webkit-mobile',    use: devices['iPhone 14'] },
  { name: 'android',          use: devices['Pixel 7'] },
]
```

```js
test('checkout — happy journey', async ({ page }) => {
  await page.goto('/cart');
  await page.getByRole('button', { name: 'Checkout' }).click();   // role, not CSS
  await page.getByLabel('Card number').fill(TEST_CARD);
  await page.getByRole('button', { name: 'Pay' }).click();
  await expect(page.getByText('Order confirmed')).toBeVisible();   // observable outcome
});
```

The other four paths at E2E scale:

- **Bad:** submit an invalid card → assert a typed inline error, no `500` page.
- **Bumpy:** `route.fulfill` a `429` twice → assert retry + spinner, then success.
- **Chaos:** kill the API container mid-pay (fault injector / `docker kill` in a separate harness, not the browser runner) → assert no double-charge; consistent state on retry.
- **Death:** drive sustained concurrency with k6/Artillery (a separate load runner, not Playwright) → assert breaker trips + graceful degradation.

When driving the browser interactively via the Playwright MCP, send commands **one at a time** and read
each result before the next.
