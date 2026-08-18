---
body:
  - type: markdown
    attributes:
      value: |
        ## Pull Request Checklist
        
        Please ensure your pull request meets the following requirements:
        
        ### Code Quality
        - [ ] Code passes `flutter analyze` and `flutter format --set-exit-if-changed` linting
        - [ ] Code follows Flutter/Dart style guidelines
        - [ ] All existing tests pass
        - [ ] New tests added for new functionality
        - [ ] Widget tests added for UI changes
        
        ### Security & Compliance
        - [ ] No secrets or credentials in code
        - [ ] Firebase configuration validated
        - [ ] Dependencies are up-to-date and secure
        
        ### Documentation
        - [ ] README updated if needed
        - [ ] DartDoc generated if applicable
        
        ## Description
        
        Provide a clear description of the changes:
        
        ### What Changed
        [Summary of changes]
        
        ### Why Changes Are Needed
        [Reason for the change]
        
        ### How It Was Tested
        [Testing details]
        
        ## Testing
        
        - [ ] All tests pass locally (`flutter test`)
        - [ ] Widget tests pass for UI changes
        - [ ] Manual testing completed if applicable
        - [ ] Integration with backend tested if needed
        
        ## Merge Checklist
        
        - [ ] Changes have been reviewed
        - [ ] Approved by at least one maintainer
        - [ ] Branch is up to date with base branch
        - [ ] All CI checks pass
        - [ ] No conflicts with base branch
        
        Co-authored-by: openhands <openhands@all-hands.dev>
