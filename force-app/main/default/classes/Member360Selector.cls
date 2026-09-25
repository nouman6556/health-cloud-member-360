/**
 * Loads the whole member view in ONE SOQL query using parent-child
 * subqueries. Tests assert this query budget so it can't regress.
 */
public inherited sharing class Member360Selector {

    public Contact selectMember(Id memberId) {
        List<Contact> rows = [
            SELECT Id, Name, FirstName, LastName, Birthdate, Email, Phone, MailingCity, MailingState,
                (SELECT Id, Status__c, Goal__c, Start_Date__c, End_Date__c
                    FROM Care_Plans__r WHERE Status__c = 'Active' ORDER BY Start_Date__c DESC LIMIT 5),
                (SELECT Id, Team_Member_Name__c, Role__c, Phone__c, Is_Primary__c
                    FROM Care_Team_Members__r ORDER BY Is_Primary__c DESC, Role__c LIMIT 20),
                (SELECT Id, Plan_Name__c, Member_Number__c, Coverage_Type__c, Effective_Date__c, Termination_Date__c
                    FROM Coverages__r ORDER BY Effective_Date__c DESC LIMIT 10),
                (SELECT Id, Encounter_Date__c, Encounter_Type__c, Provider_Name__c, Primary_Diagnosis__c
                    FROM Encounters__r ORDER BY Encounter_Date__c DESC LIMIT 50)
            FROM Contact
            WHERE Id = :memberId
            WITH USER_MODE
        ];
        return rows.isEmpty() ? null : rows[0];
    }
}
