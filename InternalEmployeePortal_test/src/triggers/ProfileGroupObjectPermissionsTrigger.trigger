trigger ProfileGroupObjectPermissionsTrigger on Profile_Group_Object_Permission__c (before insert, before update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        ProfileGroupObjectPermissionsHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        ProfileGroupObjectPermissionsHandler.beforeUpdate(Trigger.new);
    }

}