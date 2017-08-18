public class ObjectPermissionHandler {

    public static void beforeInsert(List<Object_Permissions__c> newRecords) {
        ObjectPermissionHelper.markAsErrorNotUniqPair(newRecords);
    }

    public static void beforeUpdate(List<Object_Permissions__c> newRecords) {
        ObjectPermissionHelper.markAsErrorNotUniqPair(newRecords);
    }
    
}