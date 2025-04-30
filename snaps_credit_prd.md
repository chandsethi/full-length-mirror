Since each snap analysis costs real money, we want to limit the number of outfit snaps a user can analyse.

We do this by introducing a credit system. Users only gets 10 free credits. Each outfit analysis costs 1 credit. 

For users, the word "Credit" is not used anywhere. Instead, the term is "Snap". For example, instead of "7 credits left", we say "7 snaps left".

Steps:
1. On the camera UI, at top center add a translucent pill with the text "N snaps left". 
2. When user submits an image for review (from camera tap or photos upload), N goes to N-1
3. On tapping the pill, user is taken to a new page (creditView) where it all it says for now is "N snaps left"
4. When N reaches 0, and user taps the camera or uploads an image from photos, we open creditView instead of sending image for analysis. This creditview ofcourse shows 0 snaps left
5. We should log it somewhere: change in snap credit balance and timestamp of it happening.

Future gazing:
* In app purchase of Snaps.
* Invite friend to get free Snaps
* Limiting to one snap per day

Phase by Phase Expectations 
1. In this first dev version, we simply want the credit balance to not reset after app relaunch. It's okay if it resets after every re-installs. 

2. In phase 2 where we send test flight invites to friends and family. In this phase, 
a) we don't want to add auth
b) we want the ability to purchase via IAP
c) we want safety such that users can't reinstall to get initial 10 credits again
d) if user had paid snaps and deletes the app, they can still 'restore purchase'


3. In phase 3, we will launch publically. Here we will add auth. This version will have 'invite friends to get free snaps' feature 


Read file: snaps_credit_prd.md
## Final Approach - Phased Implementation

### Phase 1 (Immediate)
- Implement basic snap credit system with UserDefaults persistence
- Add simple UI for displaying remaining snaps
- Implement local transaction logging
- Support persistence across app relaunches but not reinstalls

### Phase 2 (TestFlight)
- Add IAP for purchasing additional snaps
- Implement device fingerprinting to prevent reinstall abuse
- Add StoreKit integration for purchase restoration
- Ensure all functionality works without auth

### Phase 3 (Public Launch)
- Implement user authentication


## Detailed Implementation for Phase 1

1. **Create SnapsManager Class**
   - Create a singleton service to manage snap credits
   - Store initial 10 credits in UserDefaults
   - Implement methods for checking, using, and logging snap transactions
   - Add transaction logging to a local file

2. **Modify ContentView**
   - Add translucent pill at below camera button showing "N snaps left"
   - Make pill tappable to navigate to CreditView
   - Intercept camera/photo actions to check snap availability
   - Show CreditView instead of processing when snaps are depleted

3. **Create CreditView**
   - Simple view showing remaining snaps count
   - Placeholder text for future purchase options
   - Navigation back to main camera view

4. **Transaction Logging**
   - Create a simple JSON file for storing transaction history
   - Log each transaction with:
     - Transaction ID (UUID)
     - Amount changed (-1 for now)
     - Timestamp
     - Type of transaction ("consumption")

5. **App Integration**
   - Initialize SnapsManager at app startup
   - Check for existing credits in UserDefaults
   - Set up environment object for views to access
   - Implement proper state handling for UI updates

This implementation focuses on the core requirements for Phase 1 while establishing a foundation that can be extended for Phases 2 and 3 without major architectural changes.
