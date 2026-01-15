#!/usr/bin/env pwsh
# Purpose: Convert TODO tests to working tests with AI guidance
# Why: Helps developers implement scaffolded tests systematically
# How: Scans for TODOs, provides context and guidance

# Source common utilities
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path "$ScriptDir/qa-common.ps1")) {
    Write-Host "Error: qa-common.ps1 not found in $ScriptDir" -ForegroundColor Red
    exit 1
}

. "$ScriptDir/qa-common.ps1"

Write-Host "🔨 Implementing test TODOs..."
Write-Host ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 1: Check and generate architecture
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test-AndGenerateArchitecture

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 2: Load context
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$archContext = Get-ArchitectureContext
$featureContext = Get-FeatureContext

$language = if ($archContext -and $archContext.Language) { $archContext.Language } else { Get-ProjectLanguage }
$framework = if ($archContext -and $archContext.Framework) { $archContext.Framework } else { "unknown" }
$testFramework = Get-TestFramework

Write-Section "📊 Context Loaded"
Write-Host "Language:        $language"
Write-Host "Framework:       $framework"
Write-Host "Test Framework:  $testFramework"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 3: Scan for TODOs
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write-Section "🔍 Scanning for TODO tests"

$todoFiles = Find-TestTodos -TestDir "tests"

if ($todoFiles.Count -eq 0) {
    Write-Host "✓ No TODO tests found. All tests are implemented!"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  • Run tests: $testFramework tests/"
    Write-Host "  • Review quality: /gbm.qa.review-tests"
    exit 0
}

$todoCount = $todoFiles.Count
Write-Host "Found $todoCount file(s) with TODOs:"
Write-Host ""

foreach ($file in $todoFiles) {
    $todoDetails = Get-TodoDetails -FilePath $file.FullName
    $todoLines = $todoDetails.Count
    Write-Host "  • $($file.FullName) ($todoLines TODO(s))"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 4: Provide implementation guidance
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write-Section "📝 Implementation Guidance"

Write-Host @'
To implement TODO tests, follow the AAA pattern:

1. **Arrange**: Set up test data and dependencies
   - Use fixtures from tests/fixtures/
   - Create test instances
   - Set up mocks

2. **Act**: Execute the code under test
   - Call the function/method
   - Trigger the behavior

3. **Assert**: Verify the results
   - Check return values
   - Verify state changes
   - Validate mock calls

'@

# Framework-specific guidance
switch ($testFramework) {
    "pytest" {
        Write-Host @'
### pytest Example

```python
def test_user_creation(user_data, db_session):
    """Test user creation with valid data"""
    # Arrange
    user_service = UserService(db_session)

    # Act
    user = user_service.create_user(user_data)

    # Assert
    assert user.id is not None
    assert user.name == user_data["name"]
    assert db_session.query(User).count() == 1
```

'@
    }
    { $_ -in "jest", "vitest" } {
        Write-Host @'
### Jest/Vitest Example

```javascript
test('user creation with valid data', () => {
  // Arrange
  const userData = createUserData();
  const userService = new UserService();

  // Act
  const user = userService.createUser(userData);

  // Assert
  expect(user.id).toBeDefined();
  expect(user.name).toBe(userData.name);
});
```

'@
    }
    "phpunit" {
        Write-Host @'
### PHPUnit Example

```php
public function testUserCreation(): void
{
    // Arrange
    $userData = $this->createUserData();
    $userService = new UserService();

    // Act
    $user = $userService->createUser($userData);

    // Assert
    $this->assertNotNull($user->id);
    $this->assertEquals($userData['name'], $user->name);
}
```

'@
    }
    "junit" {
        Write-Host @'
### JUnit Example

```java
@Test
public void testUserCreation() {
    // Arrange
    Map<String, Object> userData = createUserData();
    UserService userService = new UserService();

    // Act
    User user = userService.createUser(userData);

    // Assert
    assertNotNull(user.getId());
    assertEquals(userData.get("name"), user.getName());
}
```

'@
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 5: Show feature-specific context
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if ($featureContext.AcceptanceCriteria -and $featureContext.AcceptanceCriteria.Count -gt 0) {
    Write-Section "✅ Acceptance Criteria to Test"
    Write-Host "Ensure each AC has corresponding tests:"
    Write-Host ""
    $featureContext.AcceptanceCriteria | Select-Object -First 10 | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "Reference ACs in test docstrings:"
    Write-Host '  """Test user creation (AC1)"""'
    Write-Host ""
}

if ($featureContext.ArchitectureContext) {
    Write-Section "🏗️ Feature Architecture Context"
    Write-Host "Review feature architecture for implementation details:"
    Write-Host "  $($featureContext.ArchitectureContext)"
    Write-Host ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 6: Generate implementation report
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

New-Item -ItemType Directory -Force -Path ".gobuildme/specs/qa-test-scaffolding" | Out-Null

$report = @"
# Test Implementation Guide

**Generated**: $(Get-Date)
**Language**: $language
**Framework**: $framework
**Test Framework**: $testFramework

## TODO Tests Found

"@

foreach ($file in $todoFiles) {
    $todoDetails = Get-TodoDetails -FilePath $file.FullName
    $report += @"

### $($file.FullName)

``````
$(($todoDetails | ForEach-Object { $_.Line }) -join "`n")
``````

"@
}

$report += @'

## Implementation Checklist

For each TODO test:

- [ ] Review the TODO description
- [ ] Identify the code under test
- [ ] Determine test data needed
- [ ] Write Arrange section (setup)
- [ ] Write Act section (execute)
- [ ] Write Assert section (verify)
- [ ] Remove TODO marker
- [ ] Run the test to verify it passes
- [ ] Check coverage impact

## AAA Pattern Template

```
def test_feature():
    """Test description (AC reference)"""
    # Arrange: Set up test data and dependencies
    # ...

    # Act: Execute the code under test
    # ...

    # Assert: Verify the results
    # ...
```

## Tips

1. **Start Simple**: Implement happy path tests first
2. **Use Fixtures**: Leverage generated fixtures for test data
3. **One Assertion**: Focus on one behavior per test
4. **Descriptive Names**: Use clear, descriptive test names
5. **Document ACs**: Reference acceptance criteria in docstrings

## Next Steps

1. Implement TODOs systematically (one file at a time)
2. Run tests after each implementation
3. Check coverage: validate-coverage.sh
4. Review quality: /gbm.qa.review-tests

'@

Set-Content -Path ".gobuildme/specs/qa-test-scaffolding/implementation-guide.md" -Value $report

Write-Section "✅ Implementation Guide Generated"
Write-Host "📄 Guide saved to: .gobuildme/specs/qa-test-scaffolding/implementation-guide.md"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Review TODO files listed above"
Write-Host "  2. Implement tests following AAA pattern"
Write-Host "  3. Run tests: $testFramework tests/"
Write-Host "  4. Review quality: /gbm.qa.review-tests"
Write-Host ""
Write-Host "💡 Tip: Implement one file at a time, run tests frequently"
Write-Host ""
