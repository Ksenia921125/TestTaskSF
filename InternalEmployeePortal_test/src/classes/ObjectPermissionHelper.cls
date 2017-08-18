public with sharing class ObjectPermissionHelper {

    private static Map<String, Id> objectPermissionRecordTypes {
        get {
            if (objectPermissionRecordTypes == null) {
                objectPermissionRecordTypes = new Map<String, Id>();
                
                List<RecordType> recordTypes = [
                    SELECT Id, DeveloperName
                    FROM RecordType
                    WHERE SobjectType = 'Object_Permissions__c'
                    LIMIT 100
                ];

                for (RecordType rec : recordTypes) {
                    objectPermissionRecordTypes.put(rec.DeveloperName, rec.Id);
                }
            }

            return objectPermissionRecordTypes;
        }
    }

    public static void markAsErrorNotUniqPair(List<Object_Permissions__c> newRecords) {
        Map<Id, List<Object_Permissions__c>> existingRecords    = getExistingRecords(newRecords);
        Map<Id, List<Object_Permissions__c>> newRecordsMap      = new Map<Id, List<Object_Permissions__c>>();

        for (Object_Permissions__c opItem : newRecords) {
            if (newRecordsMap.containsKey(opItem.RecordTypeId)) {
                newRecordsMap.get(opItem.RecordTypeId).add(opItem);
            } else {
                newRecordsMap.put(opItem.RecordTypeId, new List<Object_Permissions__c>{opItem});
            }
        }
        
        String recordTypeId;

        Set<Object_Permissions__c> invalidRecords = new Set<Object_Permissions__c>();

        recordTypeId = objectPermissionRecordTypes.get('CRUD');
        invalidRecords.addAll(getNotUniqObjects(newRecordsMap.get(recordTypeId), existingRecords.get(recordTypeId)));

        recordTypeId = objectPermissionRecordTypes.get('FLS');
        invalidRecords.addAll(getNotUniqObjects(newRecordsMap.get(recordTypeId), existingRecords.get(recordTypeId)));

        recordTypeId = objectPermissionRecordTypes.get('OwnerSharing');
        invalidRecords.addAll(getNotUniqObjects(newRecordsMap.get(recordTypeId), existingRecords.get(recordTypeId)));
        
        recordTypeId = objectPermissionRecordTypes.get('OtherSharing');
        invalidRecords.addAll(getNotUniqObjects(newRecordsMap.get(recordTypeId), existingRecords.get(recordTypeId)));

        for (Object_Permissions__c opItem : newRecords) {
            if (invalidRecords.contains(opItem)) {
                opItem.addError(System.Label.Not_unique_record);
            }
        }
    }

    private static Map<Id, List<Object_Permissions__c>> getExistingRecords(List<Object_Permissions__c> newRecords) {
        Map<Id, List<Object_Permissions__c>> existingRecordsMap = new Map<Id, List<Object_Permissions__c>>();

        Set<String> newRecordsPGOPId = new Set<String>();
        for (Object_Permissions__c opItem : newRecords) {
            newRecordsPGOPId.add(opItem.Profile_Group_Object_Permission__c);
        }

        List<Object_Permissions__c> existingRecords = [
            SELECT Profile_Group_Object_Permission__c, Field_API_Name__c
            FROM Object_Permissions__c
            WHERE Profile_Group_Object_Permission__c = :newRecordsPGOPId
            LIMIT 49900
        ];

        for (Object_Permissions__c opItem : existingRecords) {
            if (existingRecordsMap.containsKey(opItem.RecordTypeId)) {
                existingRecordsMap.get(opItem.RecordTypeId).add(opItem);
            } else {
                existingRecordsMap.put(opItem.RecordTypeId, new List<Object_Permissions__c>{opItem});
            }
        }

        return existingRecordsMap;
    }

    private static List<Object_Permissions__c> getNotUniqObjects(List<Object_Permissions__c> newRecords, List<Object_Permissions__c> existingRecords) {
        List<Object_Permissions__c> notUniqObjects = new List<Object_Permissions__c>();

        if (newRecords.isEmpty() || existingRecords.isEmpty()) {
            return notUniqObjects;
        }

        Id recordTypeIdFromExisting = existingRecords.get(0).RecordTypeId;

        if (recordTypeIdFromExisting == objectPermissionRecordTypes.get('FLS')) {

            Map<Id, Set<String>> flsPermissionsPair = new Map<Id, Set<String>>();
            for (Object_Permissions__c opItem : existingRecords) {
                if (flsPermissionsPair.containsKey(opItem.Profile_Group_Object_Permission__c)) {
                    flsPermissionsPair.get(opItem.Profile_Group_Object_Permission__c).add(opItem.Field_API_Name__c);
                } else {
                    Set<String> fieldsAPINameSet = new Set<String>();
                    fieldsAPINameSet.add(opItem.Field_API_Name__c);
                    flsPermissionsPair.put(opItem.Profile_Group_Object_Permission__c, fieldsAPINameSet);
                }
            }

            for (Object_Permissions__c opItem : newRecords) {
                Boolean isNotUniq = (
                    flsPermissionsPair.containsKey(opItem.Profile_Group_Object_Permission__c) &&
                    flsPermissionsPair.get(opItem.Profile_Group_Object_Permission__c).contains(opItem.Field_API_Name__c)
                );
 
                if (isNotUniq) {
                    notUniqObjects.add(opItem);
                }
            }

        } else {

            Set<String> existingPGOPId = new Set<String>();
            for (Object_Permissions__c opItem : existingRecords) {
                existingPGOPId.add(opItem.Profile_Group_Object_Permission__c);
            }

            for (Object_Permissions__c opItem : newRecords) {
                if (existingPGOPId.contains(opItem.Profile_Group_Object_Permission__c)) {
                    notUniqObjects.add(opItem);
                }
            }

        }
        
        return notUniqObjects;
    }

}