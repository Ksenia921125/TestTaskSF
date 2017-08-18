public with sharing class ProfileGroupObjectPermissionsHandler {

    public static void beforeInsert(List<Profile_Group_Object_Permission__c> newRecords) {
        ProfileGroupObjectPermissionsHelper.markAsErrorNotUniqPair(newRecords);
    }

    public static void beforeUpdate(List<Profile_Group_Object_Permission__c> newRecords) {
        ProfileGroupObjectPermissionsHelper.markAsErrorNotUniqPair(newRecords);
    }
}