/**
 * Assembles the Member 360 view model from a single selector call and
 * derives coverage status, utilisation counts and care alerts.
 * The derivation (build) is pure, so it is unit-testable without data.
 */
public with sharing class Member360Service {

    public static final Integer QUERY_BUDGET = 1;
    public static final Integer RECENT_ENCOUNTER_LIMIT = 10;

    public class Member360 {
        @AuraEnabled public Id memberId;
        @AuraEnabled public String name;
        @AuraEnabled public Integer age;
        @AuraEnabled public String location;
        @AuraEnabled public String coverageStatus;          // Active | Terminated | No coverage
        @AuraEnabled public Member_Coverage__c activeCoverage;
        @AuraEnabled public List<Member_Coverage__c> coverages;
        @AuraEnabled public List<Care_Plan__c> activeCarePlans;
        @AuraEnabled public List<Care_Team_Member__c> careTeam;
        @AuraEnabled public List<Encounter__c> recentEncounters;
        @AuraEnabled public Integer encountersLast12Months = 0;
        @AuraEnabled public Integer emergencyVisitsLast12Months = 0;
        @AuraEnabled public List<String> alerts = new List<String>();
    }

    private final Member360Selector selector;

    public Member360Service() {
        this(new Member360Selector());
    }

    @TestVisible
    private Member360Service(Member360Selector selector) {
        this.selector = selector;
    }

    public Member360 getMember360(Id memberId) {
        Contact c = selector.selectMember(memberId);
        return c == null ? null : build(c, Date.today());
    }

    @TestVisible
    private static Member360 build(Contact c, Date today) {
        Member360 m = new Member360();
        m.memberId = c.Id;
        m.name = c.Name;
        m.age = c.Birthdate == null ? null : ageOn(c.Birthdate, today);
        List<String> place = new List<String>();
        if (String.isNotBlank(c.MailingCity)) { place.add(c.MailingCity); }
        if (String.isNotBlank(c.MailingState)) { place.add(c.MailingState); }
        m.location = String.join(place, ', ');
        m.coverages = c.Coverages__r;
        m.activeCarePlans = c.Care_Plans__r;
        m.careTeam = c.Care_Team_Members__r;

        applyCoverage(m, today);
        applyUtilisation(m, c.Encounters__r, today);
        applyAlerts(m);
        return m;
    }

    private static void applyCoverage(Member360 m, Date today) {
        m.coverageStatus = m.coverages.isEmpty() ? 'No coverage' : 'Terminated';
        for (Member_Coverage__c cov : m.coverages) {
            Boolean started = cov.Effective_Date__c != null && cov.Effective_Date__c <= today;
            Boolean notEnded = cov.Termination_Date__c == null || cov.Termination_Date__c >= today;
            if (started && notEnded && (m.activeCoverage == null || cov.Coverage_Type__c == 'Medical')) {
                m.activeCoverage = cov;
                m.coverageStatus = 'Active';
            }
        }
    }

    private static void applyUtilisation(Member360 m, List<Encounter__c> encounters, Date today) {
        m.recentEncounters = new List<Encounter__c>();
        Datetime cutoff = Datetime.newInstance(today.addMonths(-12), Time.newInstance(0, 0, 0, 0));
        for (Encounter__c e : encounters) {
            if (m.recentEncounters.size() < RECENT_ENCOUNTER_LIMIT) {
                m.recentEncounters.add(e);
            }
            if (e.Encounter_Date__c != null && e.Encounter_Date__c >= cutoff) {
                m.encountersLast12Months++;
                if (e.Encounter_Type__c == 'Emergency') {
                    m.emergencyVisitsLast12Months++;
                }
            }
        }
    }

    private static void applyAlerts(Member360 m) {
        if (m.coverageStatus != 'Active') {
            m.alerts.add('No active coverage on file.');
        }
        Boolean hasPcp = false;
        for (Care_Team_Member__c ctm : m.careTeam) {
            if (ctm.Role__c == 'Primary Care Physician') { hasPcp = true; }
        }
        if (!hasPcp) {
            m.alerts.add('No primary care physician assigned.');
        }
        if (m.emergencyVisitsLast12Months >= 2) {
            m.alerts.add(m.emergencyVisitsLast12Months + ' emergency visits in the last 12 months. Consider care management outreach.');
        }
        if (m.activeCarePlans.isEmpty() && m.encountersLast12Months >= 4) {
            m.alerts.add('High utilisation with no active care plan.');
        }
    }

    @TestVisible
    private static Integer ageOn(Date birthdate, Date today) {
        Integer age = today.year() - birthdate.year();
        if (today.month() < birthdate.month() || (today.month() == birthdate.month() && today.day() < birthdate.day())) {
            age--;
        }
        return age;
    }
}
