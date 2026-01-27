# PLAN: Manager Registration

## Objectives
1.  **Backend Verification**: Confirm `auth_controller.rb` correctly handles the `role` parameter. (It seems it does).
2.  **Frontend Logic**: Modify `SessionManager.signup` to include the `role` in the request body.
3.  **Frontend UI**: Add a role selection mechanism (e.g., a Dropdown or Switch) to the registration form in `AccessScreens.dart`.
4.  **Integration Test**: Verify that a user registered as a manager can access manager features (if any) or shows as a manager in the session.

## Success Criteria
- User can select "Manager" during signup.
- The `role` sent to the backend is "manager".
- After signup, the local `User` object has `role: 'manager'`.
- The `SessionManager` correctly identifies the user as `isManager`.
