Sign in to the toy marketplace app as dolla@example.com using the Playwright browser.

Use the ui-end-to-end-tester agent to do the following:

1. Check if the dev server is running on port 8080. If not, start it with `npm run dev` in the project directory and wait for it to be ready.
2. Navigate to http://localhost:8080/auth
3. If already signed in as dolla@example.com, report success and take a screenshot — no need to sign in again.
4. If a different user is signed in, clear localStorage to sign out first, then reload the page.
5. Fill in the sign-in form:
   - Email: dolla@example.com
   - Password: Test1234!
6. Submit the form and wait for redirect to the home page.
7. Navigate to /profile to confirm the logged-in user shows name "多拉a夢 野比" or nickname "我愛銅鑼燒".
8. Take a screenshot saved to `test_images/signin-dolla-profile-001.png`.
9. Report success with the screenshot path, or report any errors encountered.
