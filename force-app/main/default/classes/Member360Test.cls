@IsTest
private class Member360Test {

    private static User careUser() {
        return TestUsers.withPermissionSet('Member_360_User');
    }

    @IsTest
    static void loadsWholeViewWithinQueryBudget() {
        System.runAs(careUser()) {
            Contact c = TestDataFactory.fullMember();

            Test.startTest();
            Integer before = Limits.getQueries();
            Member360Service.Member360 m = Member360Controller.getMember360(c.Id);
            Integer used = Limits.getQueries() - before;
            Test.stopTest();

            Assert.areEqual(Member360Service.QUERY_BUDGET, used, 'Member 360 must load in a single SOQL query');
            Assert.areEqual(54, m.age);
            Assert.areEqual('Chicago, IL', m.location);
            Assert.areEqual('Active', m.coverageStatus);
            Assert.areEqual('Medical', m.activeCoverage.Coverage_Type__c);
            Assert.areEqual(2, m.coverages.size());
            Assert.areEqual(1, m.activeCarePlans.size());
            Assert.areEqual('Primary Care Physician', m.careTeam[0].Role__c, 'Primary team member sorted first');
            Assert.areEqual(4, m.recentEncounters.size());
            Assert.areEqual(3, m.encountersLast12Months);
            Assert.areEqual(2, m.emergencyVisitsLast12Months);
            Assert.areEqual(1, m.alerts.size(), 'Only the ER-utilisation alert');
            Assert.isTrue(m.alerts[0].contains('emergency visits'));
        }
    }

    @IsTest
    static void flagsMissingCoverageAndPcp() {
        System.runAs(careUser()) {
            Contact c = TestDataFactory.member('Nguyen', null);
            insert TestDataFactory.coverage(c.Id, 'Medical', Date.today().addYears(-2), Date.today().addDays(-1));

            Member360Service.Member360 m = new Member360Service().getMember360(c.Id);

            Assert.areEqual('Terminated', m.coverageStatus);
            Assert.isNull(m.activeCoverage);
            Assert.isNull(m.age);
            Assert.isTrue(m.alerts.contains('No active coverage on file.'));
            Assert.isTrue(m.alerts.contains('No primary care physician assigned.'));
        }
    }

    @IsTest
    static void flagsHighUtilisationWithoutCarePlan() {
        System.runAs(careUser()) {
            Contact c = TestDataFactory.member('Okafor', Date.newInstance(1980, 1, 1));
            List<Encounter__c> visits = new List<Encounter__c>();
            for (Integer i = 1; i <= 12; i++) {
                visits.add(TestDataFactory.encounter(c.Id, 'Office Visit', i * 10));
            }
            insert visits;

            Member360Service.Member360 m = new Member360Service().getMember360(c.Id);

            Assert.areEqual('No coverage', m.coverageStatus);
            Assert.areEqual(Member360Service.RECENT_ENCOUNTER_LIMIT, m.recentEncounters.size(), 'Recent list is capped');
            Assert.areEqual(12, m.encountersLast12Months);
            Assert.isTrue(m.alerts.contains('High utilisation with no active care plan.'));
        }
    }

    @IsTest
    static void ageHandlesBirthdayNotYetReached() {
        Date today = Date.newInstance(2026, 3, 15);
        Assert.areEqual(40, Member360Service.ageOn(Date.newInstance(1985, 3, 15), today));
        Assert.areEqual(39, Member360Service.ageOn(Date.newInstance(1985, 3, 16), today));
    }

    @IsTest
    static void unknownMemberReturnsNull() {
        System.runAs(careUser()) {
            Contact c = TestDataFactory.member('Deleted', null);
            Id missing = c.Id;
            delete c;
            Assert.isNull(Member360Controller.getMember360(missing));
        }
    }

    @IsTest
    static void userWithoutPermissionSetIsBlocked() {
        Contact c = TestDataFactory.fullMember();
        User noAccess;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            noAccess = new User(ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                LastName = 'NoAccess', Alias = 'noacc', Email = 'noaccess@example.com',
                Username = 'noaccess' + Datetime.now().getTime() + '@example.com', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Chicago');
            insert noAccess;
        }
        System.runAs(noAccess) {
            try {
                Member360Controller.getMember360(c.Id);
                Assert.fail('User-mode query should block users without Member_360_User');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
        }
    }
}
