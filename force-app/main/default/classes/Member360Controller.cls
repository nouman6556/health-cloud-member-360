public with sharing class Member360Controller {
    @AuraEnabled(cacheable=true)
    public static Member360Service.Member360 getMember360(Id memberId) {
        try {
            return new Member360Service().getMember360(memberId);
        } catch (QueryException e) {
            throw new AuraHandledException('You do not have access to this member view.');
        }
    }
}
