/** Synthetic data factory: realistic-looking but entirely fictional members. */
@IsTest
public class TestDataFactory {

    public static Contact member(String lastName, Date birthdate) {
        Contact c = new Contact(FirstName = 'Synthetic', LastName = lastName, Birthdate = birthdate,
            MailingCity = 'Chicago', MailingState = 'IL', Email = lastName.toLowerCase() + '@example.com');
        insert c;
        return c;
    }

    public static Member_Coverage__c coverage(Id memberId, String type, Date effective, Date termination) {
        return new Member_Coverage__c(Member__c = memberId, Coverage_Type__c = type, Plan_Name__c = 'Synthetic ' + type + ' PPO',
            Member_Number__c = 'SYN' + String.valueOf(Math.abs(Crypto.getRandomInteger())).left(8),
            Effective_Date__c = effective, Termination_Date__c = termination);
    }

    public static Encounter__c encounter(Id memberId, String type, Integer daysAgo) {
        return new Encounter__c(Member__c = memberId, Encounter_Type__c = type,
            Encounter_Date__c = Datetime.now().addDays(-daysAgo), Provider_Name__c = 'Synthetic Clinic', Primary_Diagnosis__c = 'Z00.00');
    }

    public static Care_Team_Member__c careTeam(Id memberId, String role, Boolean isPrimary) {
        return new Care_Team_Member__c(Member__c = memberId, Role__c = role, Is_Primary__c = isPrimary,
            Team_Member_Name__c = 'Synthetic ' + role, Phone__c = '555-0100');
    }

    public static Care_Plan__c carePlan(Id memberId, String goal) {
        return new Care_Plan__c(Member__c = memberId, Status__c = 'Active', Goal__c = goal, Start_Date__c = Date.today().addMonths(-2));
    }

    /** A fully populated member used by most tests. */
    public static Contact fullMember() {
        Contact c = member('Rivera', Date.today().addYears(-54).addDays(-10));
        insert new List<SObject>{
            coverage(c.Id, 'Medical', Date.today().addYears(-1), null),
            coverage(c.Id, 'Dental', Date.today().addYears(-3), Date.today().addYears(-1)),
            careTeam(c.Id, 'Primary Care Physician', true),
            careTeam(c.Id, 'Care Manager', false),
            carePlan(c.Id, 'HbA1c below 7% within 6 months'),
            encounter(c.Id, 'Office Visit', 20),
            encounter(c.Id, 'Emergency', 60),
            encounter(c.Id, 'Emergency', 120),
            encounter(c.Id, 'Telehealth', 500)
        };
        return c;
    }
}
