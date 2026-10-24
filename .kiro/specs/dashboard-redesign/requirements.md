# Requirements Document

## Introduction

This feature redesigns the Journey dashboard (`lib/features/dashboard/`) so that journaling feels inviting rather than forced, and adds a weekly streak page.

The redesign:

- Adds a dismissible Premium banner at the very top of the dashboard for users without Premium, linking to the existing Insights screen (`Routes.insights`).
- Removes the daily-quota UI: the `TodayCard` ("n of 10 entries today", progress bar, otter face, streak nudge), the `WakeUpCard` ("When did you wake up today"), and the two standalone log buttons.
- Rebuilds the top bar: a rounded greeting box ("Hey {name}") with an otter face on its right side that shows a different random expression on every app launch, followed by a larger, tappable streak button and a proportionally larger settings button.
- Removes the daily entry limit. Users can log as many entries per day as they want; the "entries per day" setting is only a preference.
- Adds a Weekly Streak page, opened from the streak button, showing Monday-to-Sunday tick boxes, a heat gauge from 0 to 7 with a fire symbol, and a static lying-down otter.
- Puts the "Log an event" button in one rounded "Enter your log" card with a light green-brown gradient. The whole Dashboard has a matte light blue background.
- Keeps the Insights teaser card unchanged.
- Turns the log history into its own scrollable region with an expand control that animates the history to full screen.
- Removes the otter from every log history tile.

Context and constraints from the existing code and steering files:

- No Premium or paid flag exists today. This feature introduces a local, mocked Premium status (default: not Premium). No payment processing is in scope. Per `tech.md`, the mock MUST carry a `TODO(post-mvp)` comment pointing at the future paywall/cloud work.
- `MockPythonBackend` keeps all state in memory and resets on every app restart. The "different otter face on every launch" requirement needs a value that survives an app restart, so it needs a persisted local store.
- The display name comes from `UserPrefs.displayName` (set during the assessment's `display_name` question and editable in Settings), exposed through `AppController.prefs`.
- Week boundaries use the device's local time zone. A week runs from Monday 00:00 to the following Monday 00:00.
- The UI uses Flutter built-ins (`ChangeNotifier`, `ListenableBuilder`), `go_router`, and the `material_ui` package. Animations respect the platform "reduce motion" setting, as `OtterMascot` already does.

Assumptions (confirmed by the user):

- A day counts as a Logged_Day when it has at least 1 saved entry. This matches the user's wording ("for whatever day a log has been filed") and the default `streakMinEntries` of 1.
- Dismissing the Premium banner hides it until the next app launch. It reappears on the next launch while the user is still not Premium.
- The banner price is a placeholder constant (e.g. "$2.99/month") until real pricing exists.
- The otter face sits inside the greeting box, to the right of the "Hey {name}" text. It does not need to be animated.
- There is no daily entry limit. The merged log buttons are always enabled, whatever `entriesPerDay` is set to. The post-save snackbar shows no "n of N" counts.
- The Insights screen stays reachable for all users. Premium status only controls the banner.

## Glossary

- **App**: The Journey Flutter application as a whole, including its routing, startup logic, and local stores.
- **Dashboard**: The home screen of the app (`DashboardScreen`, route `/`).
- **Premium_Status**: A locally stored boolean saying whether the user has Premium (the ability to access Insights). Default: not Premium. Mocked; no payment processing.
- **Premium_Banner**: A compact rectangle at the very top of the Dashboard that invites the user to pay for Premium. It contains a "click here" hyperlink and a close (X) button.
- **Insights_Screen**: The existing Insights screen (`InsightsScreen`, route `/insights`).
- **Insights_Teaser**: The existing "Insights" card on the Dashboard (`_InsightsTeaser`) that opens the Insights_Screen.
- **Top_Bar**: The Dashboard row directly below the Premium_Banner that contains the Greeting_Box, the Streak_Button, and the Settings_Button, in that left-to-right order.
- **Greeting_Box**: A rounded box in the Top_Bar that shows the text "Hey {Display_Name}" and the Launch_Otter.
- **Display_Name**: The user's name as stored in `UserPrefs.displayName`. It is first entered during the initial assessment and can be edited in Settings.
- **Launch_Otter**: A static (non-animated) otter face shown inside the Greeting_Box. Its expression is chosen at random once per app launch.
- **Otter_Expression**: One of the 5 otter face expressions that `OtterMascot` can render (happiness values 1 to 5).
- **Launch_Expression_Store**: Local storage that keeps the Otter_Expression shown at the most recent app launch, so the value survives an app restart.
- **Streak_Button**: The flame-and-day-count button in the Top_Bar (currently `StreakPill`).
- **Settings_Button**: The gear icon button in the Top_Bar that opens Settings.
- **Scale_Factor**: The single size multiplier applied to both the Streak_Button and the Settings_Button relative to their current sizes.
- **Weekly_Streak_Page**: A new screen, opened from the Streak_Button, that shows weekly logging progress.
- **Current_Week**: The 7 local calendar days from Monday 00:00 through Sunday 23:59:59 that contain the current local date.
- **Logged_Day**: A calendar day with at least 1 saved log entry.
- **Weekly_Count**: The number of Logged_Days within the Current_Week. Always an integer from 0 to 7.
- **Day_Box**: One of the 7 small squares on the Weekly_Streak_Page, one per day from Monday to Sunday, each with its weekday label written above it.
- **Tick_Mark**: A check mark drawn inside a Day_Box when that day is a Logged_Day.
- **Heat_Gauge**: A meter on the Weekly_Streak_Page with tick labels 0 to 7, a needle that points at the Weekly_Count, and a fire symbol in its center.
- **Heat_Level**: The visual intensity of the Heat_Gauge (color moving toward red, plus glow or flame emphasis). Heat_Level is determined only by the Weekly_Count.
- **Resting_Otter**: A static illustration at the bottom of the Weekly_Streak_Page of an otter lying down, with one paw on its head, looking at the viewer.
- **Log_Card**: A rounded card on the Dashboard with a light green-brown gradient background, the text "Enter your log" centered at its top, and the Log_Event_Button below that text.
- **Log_Event_Button**: The "Log an event" button with a plus icon. It opens the Log_Entry_Screen.
- **Entries_Per_Day_Preference**: The `UserPrefs.entriesPerDay` setting: how many entries the user would like to log per day. It is a preference only and never limits how many entries can be saved.
- **Log_Entry_Screen**: The existing screen that opens a draft entry for editing and saving (`LogEntryScreen`, route `/log`).
- **Log_History**: The Dashboard section, titled "Log History", that lists saved entries grouped by day, newest day first.
- **History_Viewport**: The fixed-height, independently scrollable region of the Dashboard that contains the Log_History entries.
- **Expand_Button**: The control next to the "Log History" title that switches the Log_History to the Expanded_History view.
- **Expanded_History**: The view in which the Log_History fills the whole screen.
- **Collapse_Button**: The control in the Expanded_History that returns to the normal Dashboard.
- **History_Tile**: One saved-entry card in the Log_History (`HistoryTile`).
- **Reduce_Motion**: The platform accessibility setting that asks apps to disable animations (`MediaQuery.disableAnimations`).

## Requirements

### Requirement 1: Premium status

**User Story:** As the app owner, I want the app to know whether the user has Premium, so that the Dashboard can promote Insights only to users who have not paid.

#### Acceptance Criteria

1. THE App SHALL hold exactly one Premium_Status value for the user at any time, and that value SHALL be either Premium or not Premium.
2. IF no Premium_Status value has been stored, including on the first launch after installation, THEN THE App SHALL report Premium_Status as not Premium.
3. THE Dashboard SHALL read Premium_Status only through a repository interface, so that replacing the mocked implementation with any other implementation of the same interface requires no change to Dashboard code.
4. THE mocked Premium_Status implementation SHALL carry a `TODO(post-mvp)` comment, placed at the mocked implementation's declaration, that names the paywall and cloud work which replaces the mock.
5. IF reading Premium_Status fails or does not complete within 2 seconds, THEN THE App SHALL continue loading the Dashboard without showing an error message, and THE Dashboard SHALL omit the Premium_Banner for the rest of the current app launch.
6. WHEN Premium_Status changes while the app is running, THE Dashboard SHALL use the new Premium_Status value no later than the next time the Dashboard is displayed, without an app restart.
7. THE mocked Premium_Status implementation SHALL allow Premium_Status to be set to Premium or to not Premium without any payment step, and the set value SHALL stay in effect for the rest of the current app launch or until it is set again.

### Requirement 2: Premium banner

**User Story:** As a user without Premium, I want a small, dismissible notice about Premium at the top of the Dashboard, so that I can learn about Insights and close the notice when I am not interested.

#### Acceptance Criteria

1. WHILE Premium_Status is not Premium and the Premium_Banner has not been dismissed in the current app launch, THE Dashboard SHALL display the Premium_Banner as the topmost element of the Dashboard content, above the Top_Bar, spanning the full width of the Dashboard content area.
2. WHILE Premium_Status is Premium, THE Dashboard SHALL omit the Premium_Banner and leave no empty space above the Top_Bar, including when Premium_Status changes to Premium while the Dashboard is open, without an app restart.
3. THE Premium_Banner SHALL display text that states the Premium price (a placeholder constant until real pricing exists) and that Premium unlocks Insights, followed by a hyperlink with the text "click here", and SHALL show this text in full, without clipping, at every device text scale, growing in height when the text scale is above the default.
4. WHILE the device text scale is the default (1.0), THE Premium_Banner SHALL have a height of at most 72 logical pixels and SHALL fit its full text, including the "click here" hyperlink, within at most 2 lines without truncation.
5. THE Premium_Banner SHALL display a close (X) button aligned to the top edge and the right edge of the Premium_Banner, without overlapping the banner text or the "click here" hyperlink.
6. WHEN the user taps the "click here" hyperlink, THE App SHALL navigate to the Insights_Screen without dismissing the Premium_Banner, so that the Premium_Banner is still displayed when the user returns to the Dashboard in the same app launch while Premium_Status is not Premium.
7. WHEN the user taps the close (X) button, THE Dashboard SHALL remove the Premium_Banner, move the Top_Bar up to become the topmost element of the Dashboard content with no empty space left where the Premium_Banner was, and leave Premium_Status unchanged.
8. WHEN the user returns to the Dashboard from another screen (including the Insights_Screen, Settings, the log entry screen, and the Weekly_Streak_Page) after dismissing the Premium_Banner in the same app launch, THE Dashboard SHALL keep the Premium_Banner hidden.
9. THE "click here" hyperlink and the close (X) button SHALL each have a tap target of at least 48 by 48 logical pixels, and SHALL expose accessibility labels that state their action ("Open Insights" for the hyperlink and "Dismiss Premium banner" for the close button).
10. WHEN the app launches while Premium_Status is not Premium, THE Dashboard SHALL display the Premium_Banner, regardless of whether the Premium_Banner was dismissed during a previous app launch.
11. IF reading Premium_Status fails, THEN THE Dashboard SHALL omit the Premium_Banner, show no error message for the failure, and continue loading the rest of the Dashboard.

### Requirement 3: Remove daily-quota and wake-up elements

**User Story:** As a user, I want the dashboard to stop showing daily entry counts and quota progress, so that journaling does not feel forced.

#### Acceptance Criteria

1. THE Dashboard SHALL omit the today card and every part of it: the "n of N entries today" text, the entries-today progress bar and its accessibility label, the today card's otter face, and the streak nudge message. The Launch_Otter in the Greeting_Box is not part of the today card and is not covered by this criterion.
2. THE Dashboard SHALL omit the "When did you wake up today" card, and no wake-up time prompt or wake-up time control SHALL appear anywhere on the Dashboard.
3. THE Dashboard SHALL display exactly 1 Log_Event_Button, and it SHALL be inside the Log_Card. No "Log an event" button SHALL appear outside the Log_Card.
4. WHEN the user returns to the Dashboard from the log entry screen after saving an entry and no celebration is shown, THE Dashboard SHALL show 1 confirmation message that states the entry was saved, contains no digits, and disappears on its own within 4 seconds.
5. THE Dashboard SHALL display no visible text and no accessibility label that states the number of entries logged today or the `entriesPerDay` value. The streak day count on the Streak_Button and the Weekly_Count are not covered by this criterion.
6. IF the user returns to the Dashboard from the log entry screen without saving an entry, THEN THE Dashboard SHALL show no confirmation message.
7. WHEN the user returns to the Dashboard from the log entry screen after saving an entry and a celebration is shown, THE Dashboard SHALL show the celebration only, with no confirmation message.

### Requirement 4: Top bar layout and greeting

**User Story:** As a user, I want a friendly greeting with my name at the top of the dashboard, so that the app feels personal.

#### Acceptance Criteria

1. THE Top_Bar SHALL display, from left to right, the Greeting_Box, the Streak_Button, and the Settings_Button in a single row, with the Settings_Button at the right end of the Top_Bar, the Streak_Button directly to the left of the Settings_Button, and the Greeting_Box filling the remaining width to the left of the Streak_Button.
2. THE Greeting_Box SHALL display, on a single line inside a box with rounded corners of at least 12 logical pixels radius, the word "Hey" followed by one space and the Display_Name with leading and trailing whitespace removed, and SHALL NOT display a time-of-day greeting such as "Good morning".
3. IF the Display_Name is empty, contains only whitespace, or has not been loaded, THEN THE Greeting_Box SHALL display the text "Hey" with no trailing name, punctuation, or placeholder.
4. IF the greeting text is wider than the width left for it inside the Greeting_Box at the current text scale, THEN THE Greeting_Box SHALL show the greeting text on one line truncated with an ellipsis at its end, while the Launch_Otter, the Streak_Button, and the Settings_Button stay fully visible at their normal sizes and positions.
5. WHEN the user returns to the Dashboard after saving a new Display_Name in Settings, THE Greeting_Box SHALL display the saved Display_Name on the first Dashboard frame shown after the return, without an app restart.
6. IF the user leaves Settings without saving a non-empty Display_Name, THEN THE Greeting_Box SHALL keep displaying the Display_Name that was shown before the user opened Settings.
7. THE Greeting_Box SHALL expose an accessibility label containing the full untruncated greeting text ("Hey" followed by the Display_Name, or "Hey" alone when the Display_Name is empty), including when the visible text is truncated.

### Requirement 5: Random launch otter

**User Story:** As a user, I want the otter in my greeting box to show a different expression every time I open the app, so that the app feels fun to return to.

#### Acceptance Criteria

1. THE Greeting_Box SHALL display the Launch_Otter to the right of the greeting text, vertically centered within the Greeting_Box, with the whole Launch_Otter inside the Greeting_Box bounds and a size of at least 32 by 32 logical pixels.
2. THE Launch_Otter SHALL expose the accessibility label that `OtterMascot` provides today, which names the displayed Otter_Expression ("Otter looking {happiness phrase}").
3. THE Launch_Otter SHALL display the chosen Otter_Expression as a still image, with no idle animation required.
4. THE Launch_Otter SHALL display its eyes in the open state for the chosen Otter_Expression.
5. WHEN the app launches from a cold start (a new app process) and the Launch_Expression_Store holds a previous Otter_Expression with a happiness value from 1 to 5, THE App SHALL choose the Otter_Expression for the Launch_Otter at random from the 4 Otter_Expressions that differ from the stored previous Otter_Expression, each with equal probability.
6. WHEN the app launches from a cold start and the Launch_Expression_Store holds no previous Otter_Expression, or holds a value that is not a happiness value from 1 to 5, THE App SHALL choose the Otter_Expression for the Launch_Otter at random from all 5 Otter_Expressions, each with equal probability.
7. WHEN the App chooses the Otter_Expression for a launch, THE App SHALL save that Otter_Expression to the Launch_Expression_Store, replacing any previous value, so that the next cold start reads that Otter_Expression as the previous Otter_Expression.
8. WHEN the Dashboard first displays the Launch_Otter after a cold start, THE Launch_Otter SHALL show the chosen Otter_Expression from its first rendered frame, without first showing a different Otter_Expression or an expression-change transition.
9. WHILE the app process keeps running, THE Launch_Otter SHALL keep the same Otter_Expression, including when the user navigates away from the Dashboard and back and when the app moves to the background and returns to the foreground.
10. IF reading from the Launch_Expression_Store fails or does not complete within 2 seconds, THEN THE App SHALL choose the Otter_Expression at random from all 5 Otter_Expressions, finish loading the Dashboard, and show no error message to the user.
11. IF writing the chosen Otter_Expression to the Launch_Expression_Store fails, THEN THE App SHALL keep displaying the chosen Otter_Expression for the rest of the current launch, finish loading the Dashboard, and show no error message to the user.
12. FOR ALL stored previous Otter_Expressions with a happiness value from 1 to 5 and all random seeds, the chosen Otter_Expression SHALL be one of the 5 Otter_Expressions and SHALL differ from the stored previous Otter_Expression; FOR ALL absent or invalid stored values and all random seeds, the chosen Otter_Expression SHALL be one of the 5 Otter_Expressions (invariant property).

### Requirement 6: Larger, tappable streak and settings buttons

**User Story:** As a user, I want bigger streak and settings buttons and to be able to tap the streak, so that they are easier to hit and I can see my week.

#### Acceptance Criteria

1. THE Streak_Button SHALL render, at the default text scale, its flame icon size, day-count font size, horizontal padding, vertical padding, and icon-to-text gap at the Scale_Factor times their current values (current values: flame icon 22 logical pixels, day-count font size of the current `titleMedium` text style, horizontal padding 12 logical pixels, vertical padding 6 logical pixels, gap 2 logical pixels), each within ±0.5 logical pixels.
2. THE Settings_Button SHALL render, at the default text scale, its gear icon size and its tap target width and height at the same Scale_Factor times their current values (current values: icon 24 logical pixels, tap target 48 by 48 logical pixels), each within ±0.5 logical pixels.
3. THE Scale_Factor SHALL be a single constant value from 1.3 to 1.5 inclusive, applied identically to the Streak_Button and the Settings_Button.
4. THE Streak_Button SHALL keep its current visual states: WHILE today counts toward the streak (`StreakInfo.todayCounts` is true), the flame icon and day count use the flame color on the flame-tinted background, and WHILE today does not count toward the streak, the flame icon and day count use the muted text color on the secondary surface background.
5. WHEN the user taps the Streak_Button, THE App SHALL open the Weekly_Streak_Page as a new screen on top of the Dashboard, so that the Weekly_Streak_Page back control returns the user to the Dashboard.
6. THE Streak_Button SHALL expose a button-role accessibility label that states the current streak in days, states whether today has been logged yet (as the current label does), and states that activating the button opens the weekly streak.
7. WHEN the user taps the Settings_Button, THE App SHALL open Settings and, when the user returns to the Dashboard, reload the Dashboard data without clearing the visible content, as the Settings_Button does today.
8. THE Streak_Button SHALL have a tap target of at least 48 by 48 logical pixels.
9. WHILE the screen width is 320 logical pixels or more at the default text scale, THE Top_Bar SHALL display the scaled Streak_Button, with a day count of up to 3 digits, and the scaled Settings_Button fully visible, with no overflow or clipping, and the Greeting_Box SHALL take only the remaining width, truncating its text as defined in Requirement 4.
10. IF the user taps the Streak_Button 2 or more times before the Weekly_Streak_Page has finished opening, THEN THE App SHALL open exactly one Weekly_Streak_Page, so that a single back action returns the user to the Dashboard.

### Requirement 7: Weekly streak calculation

**User Story:** As a user, I want my weekly progress to count only the days of the current Monday-to-Sunday week, so that each week starts fresh.

#### Acceptance Criteria

1. WHEN the Weekly_Streak_Page is opened or reloads its entry data, THE Weekly_Streak_Page SHALL compute the Current_Week from the device's local date and local time zone at that moment, with Monday as the first day and Sunday as the last day.
2. WHEN the Weekly_Streak_Page is opened or reloads its entry data, THE Weekly_Streak_Page SHALL compute the Weekly_Count as the number of distinct Logged_Days within the Current_Week, using every entry saved before that moment, including entries saved earlier in the same app launch.
3. THE Weekly_Streak_Page SHALL assign each entry to the local calendar date of the entry's saved timestamp, so that an entry saved at Sunday 23:59:59 counts toward the week that ends on that Sunday and an entry saved at Monday 00:00:00 counts toward the week that starts on that Monday.
4. THE Weekly_Streak_Page SHALL exclude entries dated before Monday 00:00:00 of the Current_Week, and entries dated after Sunday 23:59:59 of the Current_Week, from the Weekly_Count and from the Tick_Marks.
5. WHEN the local date moves from a Sunday to the following Monday, THE Weekly_Streak_Page SHALL show a Weekly_Count of 0, no Tick_Marks, and the Heat_Level for 0 the next time the Weekly_Streak_Page is opened or reloads its entry data, until an entry is saved in the new week.
6. FOR ALL local dates, the Current_Week computed for that date SHALL start on a Monday at 00:00:00, span exactly 7 consecutive calendar days ending on a Sunday at 23:59:59, and contain that date (invariant property, including dates on daylight-saving transitions and at year boundaries).
7. FOR ALL collections of entries, the Weekly_Count SHALL equal the number of distinct local calendar dates of entries that fall within the Current_Week, and SHALL be an integer from 0 to 7 (invariant property).
8. FOR ALL collections of entries, adding further entries on a day that is already a Logged_Day SHALL leave the Weekly_Count unchanged (idempotence property).

### Requirement 8: Weekly day boxes

**User Story:** As a user, I want to see which days this week I logged, so that I can see my consistency at a glance.

#### Acceptance Criteria

1. THE Weekly_Streak_Page SHALL display exactly 7 Day_Boxes in a single horizontal row, ordered Monday to Sunday from left to right, as the first content element below the page's back control and above the Heat_Gauge.
2. THE Weekly_Streak_Page SHALL display one weekday label directly above each Day_Box and horizontally centered on that Day_Box, using the labels Mon, Tue, Wed, Thu, Fri, Sat, and Sun for the Day_Boxes from left to right.
3. WHILE a day of the Current_Week is a Logged_Day, THE Weekly_Streak_Page SHALL display a Tick_Mark inside the Day_Box for that day, where an entry belongs to the day that contains the entry's timestamp in the device's local time zone (from 00:00:00 through 23:59:59 of that local date).
4. WHILE a day of the Current_Week is not a Logged_Day, including any day after the current local date, THE Weekly_Streak_Page SHALL display the Day_Box for that day with no Tick_Mark and no other content inside it.
5. THE Weekly_Streak_Page SHALL display the Day_Box for the current local date with a highlight (such as a border or fill) that none of the other 6 Day_Boxes have, and SHALL show this highlight both when the current local date is a Logged_Day and when it is not, with the Tick_Mark still visible when the day is logged.
6. THE Weekly_Streak_Page SHALL expose an accessibility label on each Day_Box that states the full weekday name (for example "Monday"), states whether that day is logged or not logged, and, for the Day_Box of the current local date only, states that the day is today.
7. FOR ALL collections of entries, the set of Day_Boxes with a Tick_Mark SHALL equal the set of Logged_Days in the Current_Week, and the number of Tick_Marks SHALL equal the Weekly_Count (invariant property).
8. WHEN the Weekly_Streak_Page opens, THE Weekly_Streak_Page SHALL display Tick_Marks that reflect every entry saved before the page was opened.
9. WHILE the screen width is at least 320 logical pixels and the text scale is the device default, THE Weekly_Streak_Page SHALL fit all 7 Day_Boxes and their weekday labels within the screen width, with no horizontal scrolling and no truncated weekday labels.

### Requirement 9: Heat gauge

**User Story:** As a user, I want a meter that heats up as I log more days this week, so that I feel rewarded for showing up.

#### Acceptance Criteria

1. THE Weekly_Streak_Page SHALL display the Heat_Gauge horizontally centered on the page, below the Day_Boxes and above the Resting_Otter.
2. THE Heat_Gauge SHALL display 8 labeled positions, 0 through 7, in ascending order from the start of the meter to the end of the meter, with equal spacing between each pair of adjacent positions.
3. THE Heat_Gauge SHALL display a fire symbol in the center of the gauge at every Weekly_Count from 0 to 7.
4. THE Heat_Gauge SHALL position the needle, once any needle animation has finished, so that the needle points at the labeled position equal to the Weekly_Count and at no other labeled position.
5. THE Heat_Gauge SHALL display the Weekly_Count as a whole number from 0 to 7 that equals the number of Tick_Marks shown in the Day_Boxes.
6. THE Heat_Gauge SHALL show 8 visually distinct Heat_Levels, one for each Weekly_Count from 0 to 7, with a Weekly_Count of 0 producing the least intense, least red appearance and a Weekly_Count of 7 producing the most intense, reddest appearance.
7. WHILE Reduce_Motion is off, WHEN the Weekly_Streak_Page finishes loading the weekly entry data, THE Heat_Gauge SHALL animate the needle and Heat_Level in one continuous motion from 0 to the Weekly_Count, completing within 1000 milliseconds of the data finishing loading and ending with the needle at the Weekly_Count.
8. WHILE Reduce_Motion is on, WHEN the weekly entry data finishes loading or the Weekly_Count changes, THE Heat_Gauge SHALL display the needle and Heat_Level at the Weekly_Count immediately, without showing any intermediate needle position or Heat_Level.
9. THE Heat_Gauge SHALL expose a single accessibility label that states the Weekly_Count out of 7 days logged in the Current_Week, with the stated Weekly_Count equal to the number displayed by the Heat_Gauge.
10. FOR ALL Weekly_Counts a and b from 0 to 7 with a < b, the Heat_Level for b SHALL be more intense and redder than the Heat_Level for a, and the needle angle for b SHALL be further from the start of the meter than the needle angle for a (metamorphic property).
11. WHILE Reduce_Motion is off, WHEN the Weekly_Count changes while the Weekly_Streak_Page is shown (after a refresh or a retry), THE Heat_Gauge SHALL animate the needle and Heat_Level from the previous Weekly_Count to the new Weekly_Count within 1000 milliseconds and update the displayed number and accessibility label to the new Weekly_Count.
12. IF the weekly entry data is still loading or has failed to load, THEN THE Weekly_Streak_Page SHALL omit the Heat_Gauge needle and Weekly_Count number, so that no Weekly_Count is shown before the Weekly_Count is known.

### Requirement 10: Resting otter and weekly page states

**User Story:** As a user, I want a relaxed otter on my weekly page, so that the page feels calm rather than pressuring.

#### Acceptance Criteria

1. WHEN the weekly entry data has loaded, THE Weekly_Streak_Page SHALL display the Resting_Otter as the last element of the page content, horizontally centered and below the Heat_Gauge.
2. THE Resting_Otter SHALL show an otter lying down, with one paw on its head and its eyes facing the viewer, and screen readers SHALL skip it as a decorative image.
3. THE Resting_Otter SHALL be static, with no animation whether Reduce_Motion is on or off, and SHALL show the same illustration for every Weekly_Count from 0 to 7.
4. WHEN the user taps the back control or uses the system back gesture on the Weekly_Streak_Page, THE App SHALL return to the Dashboard and keep the Dashboard in the state it was in before the Weekly_Streak_Page opened, including a dismissed Premium_Banner staying hidden.
5. WHILE the weekly entry data is loading, THE Weekly_Streak_Page SHALL display a loading indicator in place of the Day_Boxes, the Heat_Gauge, and the Resting_Otter, and SHALL NOT display a Weekly_Count or any Tick_Marks.
6. IF loading the weekly entry data fails or does not complete within 10 seconds, THEN THE Weekly_Streak_Page SHALL display, in place of the Day_Boxes, the Heat_Gauge, and the Resting_Otter, an error message saying that weekly progress could not be loaded and a retry button with a tap target of at least 48 by 48 logical pixels, and SHALL NOT display a Weekly_Count or any Tick_Marks.
7. THE Weekly_Streak_Page SHALL display the back control at the top-left of the page in the loading, error, and loaded states, with a tap target of at least 48 by 48 logical pixels and an accessibility label stating that it returns to the Dashboard.
8. WHEN the user taps the retry button, THE Weekly_Streak_Page SHALL replace the error message with the loading indicator and load the weekly entry data again, with no limit on the number of retries.
9. IF the Day_Boxes, the Heat_Gauge, and the Resting_Otter together are taller than the screen height, THEN THE Weekly_Streak_Page SHALL scroll vertically so that the Resting_Otter can be reached.

### Requirement 11: Merged log card

**User Story:** As a user, I want one card to start a log from, so that the dashboard is tidy and the entry point is obvious.

#### Acceptance Criteria

1. THE Dashboard SHALL display the Log_Card below the Top_Bar and above the Insights_Teaser, with no other Dashboard element between the Top_Bar and the Log_Card or between the Log_Card and the Insights_Teaser.
2. THE Log_Card SHALL display the text "Enter your log" at the top of the Log_Card, with the horizontal center of the text aligned with the horizontal center of the Log_Card.
3. THE Log_Card SHALL display the Log_Event_Button below the "Enter your log" text, horizontally centered within the Log_Card and fully inside the Log_Card bounds on screen widths from 320 logical pixels upward.
4. THE Log_Event_Button SHALL display the label "Log an event" with a plus icon, and SHALL have a tap target of at least 48 by 48 logical pixels and an accessibility label that contains "Log an event".
5. THE Log_Card SHALL display a light green-brown gradient as its background, running from light green at the top left to light brown at the bottom right.
6. WHEN the user taps the Log_Event_Button, THE App SHALL open one Log_Entry_Screen and SHALL ignore further taps on the Log_Event_Button until the user returns to the Dashboard.
7. WHEN the user returns from the log entry screen after saving an entry, THE Dashboard SHALL reload the streak and the Log_History so that the saved entry appears in the Log_History under its day header and the Streak_Button shows the updated streak day count, before the Dashboard shows the post-save confirmation message.
8. THE Log_Card SHALL display the Log_Event_Button as enabled for any number of entries logged today, including when the number of entries logged today is equal to or greater than the Entries_Per_Day_Preference.
9. THE Log_Card SHALL NOT display a daily-limit message.
10. WHEN the user changes the Entries_Per_Day_Preference in Settings, THE Log_Card SHALL keep the Log_Event_Button enabled.
11. IF the user returns from the log entry screen without saving an entry, THEN THE Dashboard SHALL keep the streak and the Log_History as they were before the log entry screen opened and SHALL show no post-save confirmation message.
12. IF reloading the streak or the Log_History fails after the user saves an entry, THEN THE Dashboard SHALL keep displaying the previously loaded streak and Log_History and SHALL display an error message indicating that the dashboard could not be refreshed.

### Requirement 12: Insights teaser unchanged

**User Story:** As a user, I want the Insights card to stay as it is, so that I can still find Insights.

#### Acceptance Criteria

1. THE Insights_Teaser SHALL display, from left to right, a sparkle icon in the app's flame accent color, the title "Insights" with the subtitle "Reflections and a wellness score" directly below it in the muted text color, and a "soon" tag with a clock-and-lock icon, with the same text, icons, and order as the current Insights_Teaser.
2. THE Dashboard SHALL display the Insights_Teaser directly below the Log_Card and directly above the "Log History" title, with no other Dashboard element between the Log_Card and the Insights_Teaser or between the Insights_Teaser and the "Log History" title.
3. WHEN the user taps anywhere within the Insights_Teaser card bounds, THE App SHALL navigate to the Insights_Screen.
4. WHEN the user uses the back control or the system back gesture on the Insights_Screen opened from the Insights_Teaser, THE App SHALL return to the Dashboard.
5. THE Dashboard SHALL display the Insights_Teaser while Premium_Status is Premium and while it is not Premium, and whether the Premium_Banner is shown or has been dismissed.
6. THE Insights_Teaser SHALL expose a single accessibility element with the label "Insights, coming soon" that activates the same navigation as a tap, with the icon, title, subtitle, and "soon" tag excluded as separate accessibility elements.

### Requirement 13: Scrollable log history

**User Story:** As a user, I want to scroll through my log history without the whole dashboard moving, so that the top of the dashboard stays in view.

#### Acceptance Criteria

1. THE Dashboard SHALL display the title "Log History" directly above the History_Viewport, with the Expand_Button on the same row to the right of the title, and the title and Expand_Button SHALL stay outside the History_Viewport so that they do not scroll with the Log_History entries.
2. THE Dashboard SHALL display inside the History_Viewport all saved entries dated from 14 days before the current local date through the current local date, which is the same date range the Log_History covers today.
3. WHEN the user drags vertically inside the History_Viewport, THE Dashboard SHALL scroll the Log_History entries and day headers within the History_Viewport and keep the Premium_Banner, Top_Bar, Log_Card, Insights_Teaser, and "Log History" title at the same on-screen positions (0 logical pixels of movement), including when the History_Viewport is already scrolled to its first or last entry.
4. THE History_Viewport SHALL fill the vertical space from the bottom of the "Log History" title row down to the bottom safe-area edge of the screen, with a minimum height of 200 logical pixels, and SHALL keep that height regardless of the number of entries it contains.
5. IF the height of the Dashboard content above the History_Viewport plus 200 logical pixels exceeds the height between the top and bottom safe-area edges of the screen, THEN THE Dashboard SHALL render the History_Viewport at 200 logical pixels and SHALL let the user scroll the Dashboard by dragging outside the History_Viewport, so that every Dashboard element, including the full History_Viewport, can be brought fully on screen.
6. THE Log_History SHALL group entries by local calendar day, newest day first, with a day header above each group that reads "Today", "Yesterday", or the abbreviated weekday, month, and day (for example "Tue, Oct 21"), and SHALL order entries within each day by entry time, newest first, as the Log_History does today.
7. WHILE the Log_History holds 0 entries in the date range of criterion 2, THE History_Viewport SHALL display an empty-state message that invites the user to log the first entry, and THE Dashboard SHALL keep displaying the "Log History" title and the Expand_Button.
8. WHEN the user pulls down on the Dashboard content above the History_Viewport, or pulls down inside the History_Viewport while it is scrolled to its first entry, past the platform refresh trigger distance, THE Dashboard SHALL show a refresh indicator, reload the streak and the Log_History, and hide the refresh indicator when the reload completes or fails.
9. IF reloading the streak or the Log_History after a pull-to-refresh gesture fails, THEN THE Dashboard SHALL keep the previously displayed streak and Log_History entries on screen unchanged and display an error message indicating that the journal could not be refreshed.

### Requirement 14: Expanded log history

**User Story:** As a user, I want to expand my log history to the full screen, so that I can read more of my entries at once.

#### Acceptance Criteria

1. WHEN the user taps the Expand_Button, THE Dashboard SHALL show the Expanded_History, which covers the Premium_Banner, Top_Bar, Log_Card, and Insights_Teaser and occupies the full screen width and the full height between the top and bottom safe-area edges of the screen.
2. WHILE Reduce_Motion is off, WHEN the user taps the Expand_Button, THE Dashboard SHALL play an animation of the Log_History growing from the History_Viewport bounds to the Expanded_History bounds, lasting between 250 and 500 milliseconds.
3. WHILE Reduce_Motion is on, WHEN the user taps the Expand_Button, taps the Collapse_Button, or uses the system back gesture in the Expanded_History, THE Dashboard SHALL switch between the History_Viewport and the Expanded_History in a single frame, without a growing or shrinking animation.
4. WHILE the Dashboard is not showing the Expanded_History, THE Dashboard SHALL display the Log_History only inside the History_Viewport.
5. WHILE the Dashboard is showing the Expanded_History, THE Expanded_History SHALL display the "Log History" title at the top of the Expanded_History with the Collapse_Button next to the title, and SHALL omit the Expand_Button.
6. WHEN the user taps the Collapse_Button or uses the system back gesture (including the Android back button) in the Expanded_History, THE Dashboard SHALL close the Expanded_History and show the normal Dashboard view with the Premium_Banner (if it was visible before expanding), Top_Bar, Log_Card, Insights_Teaser, and History_Viewport, without leaving the Dashboard or closing the app.
7. WHILE the Dashboard is showing the Expanded_History, THE Expanded_History SHALL display the same entries, in the same order and day grouping, as the History_Viewport, SHALL scroll vertically when the entries are taller than the Expanded_History, and SHALL display the same empty-state message as the History_Viewport when no entries exist.
8. THE Expand_Button and the Collapse_Button SHALL each have a tap target of at least 48 by 48 logical pixels and an accessibility label ("Expand log history" and "Collapse log history").
9. WHILE Reduce_Motion is off, WHEN the user taps the Collapse_Button or uses the system back gesture in the Expanded_History, THE Dashboard SHALL play an animation of the Log_History shrinking from the Expanded_History bounds back to the History_Viewport bounds, lasting between 250 and 500 milliseconds.
10. WHILE a growing or shrinking animation is in progress, THE Dashboard SHALL ignore further taps on the Expand_Button and the Collapse_Button, so that one tap produces exactly one view change.
11. WHEN the Dashboard returns from the Expanded_History to the normal Dashboard view, THE History_Viewport SHALL show the same scroll position it had immediately before the user tapped the Expand_Button.

### Requirement 15: Otter-free history tiles

**User Story:** As a user, I want plain log history entries, so that the list is easier to scan.

#### Acceptance Criteria

1. THE History_Tile SHALL display the full entry text, wrapped onto as many lines as needed without truncation, and below it the entry time in the same time format the History_Tile uses today, in both the History_Viewport and the Expanded_History.
2. THE History_Tile SHALL display no otter image and no placeholder in the space the otter image occupied, so that the entry text and entry time start at the left inner padding of the History_Tile.
3. THE History_Tile SHALL expose a single accessibility label that states, in this order, the entry time, the entry text, and the happiness phrase for the entry's happiness value (1 to 5), and SHALL NOT announce its child elements or any otter description separately.
4. THE History_Tile SHALL display no mode tag of any kind.

### Requirement 16: No daily entry limit

**User Story:** As a user, I want to log as many entries as I like in a day, so that the number I set feels like a preference rather than a cap.

#### Acceptance Criteria

1. THE App SHALL allow the user to save any number of entries per day, regardless of the Entries_Per_Day_Preference.
2. THE App SHALL treat the Entries_Per_Day_Preference as a preference only, and SHALL NOT disable or hide any control for starting or saving an entry because of it.
3. THE Log_Entry_Screen SHALL NOT display an entry counter, such as "Entry {n}" or "Entry {n} of {Entries_Per_Day_Preference}", in its title or anywhere else.
