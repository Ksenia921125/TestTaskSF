public with sharing class AccessTableService {

    public class PermissionException extends Exception {}

    private static Map<String, Id> objectPermissionRecordTypes {
        get {
            if (objectPermissionRecordTypes == null) {
                objectPermissionRecordTypes = new Map<String, Id>();
                
                List<RecordType> recordTypes = [
                    SELECT Id, DeveloperName
                    FROM RecordType
                    WHERE SobjectType = 'Object_Permissions__c'
                ];

                for (RecordType rec : recordTypes) {
                    objectPermissionRecordTypes.put(rec.DeveloperName, rec.Id);
                }
            }

            return objectPermissionRecordTypes;
        }
    }


    public static List<Profile_Group_Object_Permission__c> addProfileObjectPermissions(List<Profile_Group_Object_Permission__c> profileObjects) {
        if (!Schema.sObjectType.Profile_Group_Object_Permission__c.isCreateable()) {
            throw new PermissionException();
        }

        Set<Profile_Group_Object_Permission__c> invalidRecords = new Set<Profile_Group_Object_Permission__c>();
        invalidRecords.addAll(getNotExistingSObjects('Profile', profileObjects));

        Set<Profile_Group_Object_Permission__c> profileObjectsSet = new Set<Profile_Group_Object_Permission__c>(profileObjects);
        profileObjectsSet.removeAll(invalidRecords);
        profileObjects = new List<Profile_Group_Object_Permission__c>(profileObjectsSet);

        if (profileObjects.size() > 0) {
            Database.insert(profileObjects, false);

            addCRUDPermission(profileObjects);
            addFLSPermissions(profileObjects);
        }

        return new List<Profile_Group_Object_Permission__c>(invalidRecords);
    }

    public static List<Profile_Group_Object_Permission__c> addGroupObjectPermissions(List<Profile_Group_Object_Permission__c> groupObjects) {
        if (!Schema.sObjectType.Profile_Group_Object_Permission__c.isCreateable()) {
            throw new PermissionException();
        }

        Set<Profile_Group_Object_Permission__c> invalidRecords = new Set<Profile_Group_Object_Permission__c>();
        invalidRecords.addAll(getNotExistingSObjects('Group', groupObjects));

        Set<Profile_Group_Object_Permission__c> groupObjectsSet = new Set<Profile_Group_Object_Permission__c>(groupObjects);
        groupObjectsSet.removeAll(invalidRecords);
        groupObjects = new List<Profile_Group_Object_Permission__c>(groupObjectsSet);

        if (groupObjects.size() > 0) {
            Database.insert(groupObjects, false);

            addOwnerSharingPermission(groupObjects);
            addOtherSharingPermission(groupObjects);
        }

        return new List<Profile_Group_Object_Permission__c>(invalidRecords);
    }


    private static void addCRUDPermission(List<Profile_Group_Object_Permission__c> profileObjects) {
        if (!Schema.sObjectType.Object_Permissions__c.isCreateable()) {
            throw new PermissionException();
        }

        List<Object_Permissions__c> crudPermissionList = new List<Object_Permissions__c>();

        for (Profile_Group_Object_Permission__c pgopItem : profileObjects) {
            crudPermissionList.add(
                new Object_Permissions__c(
                    Profile_Group_Object_Permission__c = pgopItem.Id,
                    RecordTypeId    = objectPermissionRecordTypes.get('CRUD'),
                    Creatable__c    = false,
                    Readable__c     = false,
                    Updatable__c    = false,
                    Deletable__c    = false,
                    Modify_All__c   = false,
                    View_All__c     = false
                )
            );
        }

        Database.insert(crudPermissionList, false);
    }

    private static void addFLSPermissions(List<Profile_Group_Object_Permission__c> profileObjects) {
        if (!Schema.sObjectType.Object_Permissions__c.isCreateable()) {
            throw new PermissionException();
        }

        List<Object_Permissions__c> flsPermissionList   = new List<Object_Permissions__c>();
        Map <String, Schema.SObjectField> schemaFields  = new Map <String, Schema.SObjectField>();

        for (Profile_Group_Object_Permission__c pgopItem : profileObjects) {
            schemaFields = Schema.getGlobalDescribe().get(pgopItem.Object_API_Name__c).getDescribe().fields.getMap();

            for (Schema.SObjectField fieldItem : schemaFields.values()) {
                flsPermissionList.add(
                    new Object_Permissions__c(
                        Profile_Group_Object_Permission__c = pgopItem.Id,
                        RecordTypeId        = objectPermissionRecordTypes.get('FLS'),
                        Field_API_Name__c   = String.valueOf(fieldItem),
                        Field_Readable__c   = false,
                        Field_Updatable__c  = false
                    )
                );
            }
        }

        Database.insert(flsPermissionList, false);
    }
    
    private static void addOwnerSharingPermission(List<Profile_Group_Object_Permission__c> groupObjects) {
        if (!Schema.sObjectType.Object_Permissions__c.isCreateable()) {
            throw new PermissionException();
        }

        List<Object_Permissions__c> ownerSharingPermissionList = new List<Object_Permissions__c>();

        for (Profile_Group_Object_Permission__c pgopItem : groupObjects) {
            ownerSharingPermissionList.add(
                new Object_Permissions__c(
                    Profile_Group_Object_Permission__c = pgopItem.Id,
                    RecordTypeId    = objectPermissionRecordTypes.get('OwnerSharing'),
                    Manager_Up__c   = false,
                    Manager_Down__c = false,
                    Role_Up__c      = false,
                    Role_Down__c    = false
                )
            );
        }

        Database.insert(ownerSharingPermissionList, false);
    }

    private static void addOtherSharingPermission(List<Profile_Group_Object_Permission__c> groupObjects) {
        if (!Schema.sObjectType.Object_Permissions__c.isCreateable()) {
            throw new PermissionException();
        }

        List<Object_Permissions__c> otherSharingPermissionList = new List<Object_Permissions__c>();

        for (Profile_Group_Object_Permission__c pgopItem : groupObjects) {
            otherSharingPermissionList.add(
                new Object_Permissions__c(
                    Profile_Group_Object_Permission__c = pgopItem.Id,
                    RecordTypeId        = objectPermissionRecordTypes.get('OtherSharing'),
                    Sharing_Describe__c = ''
                )
            );
        }

        Database.insert(otherSharingPermissionList, false);
    }

    private static List<Profile_Group_Object_Permission__c> getNotExistingSObjects(String sObjectType, List<Profile_Group_Object_Permission__c> objects) {
        String fieldName = sObjectType + '_API_Name__c';
        String searchBy = (sObjectType == 'Profile') ? 'Name' : 'DeveloperName';

        List<Profile_Group_Object_Permission__c> notExistSObject = new List<Profile_Group_Object_Permission__c>();

        Set<String> sObjectNames = new Set<String>();
        for (Profile_Group_Object_Permission__c pgopItem : objects) {
            sObjectNames.add(String.valueOf(pgopItem.get(fieldName)));
        }

        List<sObject> listSObject       =  Database.query('SELECT Id, Name FROM ' + sObjectType + ' WHERE ' + searchBy + ' IN :sObjectNames');
        Set<String> existingObjectNames = new Set<String>();
        for (sObject rec : listSObject) {
            existingObjectNames.add(String.valueOf(rec.get('Name')));
        }

        if (existingObjectNames.isEmpty()) {
            return objects;
        }

        if (existingObjectNames.size() != sObjectNames.size()) {
            for (Profile_Group_Object_Permission__c pgopItem : objects) {
                if (!existingObjectNames.contains(String.valueOf(pgopItem.get(fieldName)))) {
                    notExistSObject.add(pgopItem);
                }
            }
        }

        return notExistSObject;
    }

}