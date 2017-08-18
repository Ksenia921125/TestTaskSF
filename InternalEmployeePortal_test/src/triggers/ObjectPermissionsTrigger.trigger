trigger ObjectPermissionsTrigger on Object_Permissions__c (before insert, before update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        ObjectPermissionHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        ObjectPermissionHandler.beforeUpdate(Trigger.new);
    }

}