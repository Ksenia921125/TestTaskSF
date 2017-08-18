public with sharing class ProfileGroupObjectPermissionsHelper {

    public static void markAsErrorNotUniqPair(List<Profile_Group_Object_Permission__c> newRecords) {
        List<Profile_Group_Object_Permission__c> profileObjectPermissions = new List<Profile_Group_Object_Permission__c>();
        List<Profile_Group_Object_Permission__c> groupObjectPermissions = new List<Profile_Group_Object_Permission__c>();

        for (Profile_Group_Object_Permission__c pgopItem : newRecords) {
            if (String.isNotBlank(pgopItem.Profile_API_Name__c)) {
                profileObjectPermissions.add(pgopItem);
            } else if (String.isNotBlank(pgopItem.Group_API_Name__c)) {
                groupObjectPermissions.add(pgopItem);
            }
        }

        markAsErrorInvalidPairs('Profile', profileObjectPermissions);
        markAsErrorInvalidPairs('Group', groupObjectPermissions);
    }

    private static void markAsErrorInvalidPairs(String sObjectType, List<Profile_Group_Object_Permission__c> objects) {
        if (objects.isEmpty()) {
            return;
        }

        List<Profile_Group_Object_Permission__c> invalidRecords = new List<Profile_Group_Object_Permission__c>();

        invalidRecords = getNotUniqObjects(sObjectType, objects);
        for (Profile_Group_Object_Permission__c pgopItem : invalidRecords) {
            pgopItem.addError(System.Label.Not_unique_record);
        }
    }

    private static List<Profile_Group_Object_Permission__c> getNotUniqObjects(String sObjectType, List<Profile_Group_Object_Permission__c> objects) {
        String fieldName = sObjectType + '_API_Name__c';

        List<Profile_Group_Object_Permission__c> notUniqPairs = new List<Profile_Group_Object_Permission__c>();

        Map<String, Map<String, Profile_Group_Object_Permission__c>> pairMap = modifyToMap(objects, fieldName, 'Object_API_Name__c');
        Set<String> pairKey = pairMap.keySet();
        
        List<Profile_Group_Object_Permission__c> pgoPermissionsForCheck =
            Database.query('SELECT Id, ' + fieldName + ', Object_API_Name__c FROM Profile_Group_Object_Permission__c WHERE ' + fieldName + ' IN :pairKey');

        for (Profile_Group_Object_Permission__c pgopItem : pgoPermissionsForCheck) {
            String profileOrGroupAPIName = String.valueOf(pgopItem.get(fieldName));
            
            Boolean isNotUniqPair = (
                pairMap.containsKey(profileOrGroupAPIName) &&
                pairMap.get(profileOrGroupAPIName).containsKey(pgopItem.Object_API_Name__c)
            );
            
            if (isNotUniqPair) {
               notUniqPairs.add(pairMap.get(profileOrGroupAPIName).get(pgopItem.Object_API_Name__c));
            }

        }

        return notUniqPairs;
    }

    private static Map<String, Map<String, Profile_Group_Object_Permission__c>> modifyToMap(List<Profile_Group_Object_Permission__c> objectsList, String forFirstKey, String forSecondKey) {
        Map<String, Map<String, Profile_Group_Object_Permission__c>> resultMap = new Map<String, Map<String, Profile_Group_Object_Permission__c>>();

        for (Profile_Group_Object_Permission__c objectItem : objectsList) {
            String firstKey    = String.valueOf(objectItem.get(forFirstKey));
            String secondKey   = String.valueOf(objectItem.get(forSecondKey));

            if (resultMap.containsKey(firstKey)) {
                if (!resultMap.get(firstKey).containsKey(secondKey)) {
                    resultMap.get(firstKey).put(secondKey, objectItem);
                }
            } else {
                Map<String, Profile_Group_Object_Permission__c> includedMap = new Map<String, Profile_Group_Object_Permission__c>();
                includedMap.put(secondKey, objectItem);
                resultMap.put(firstKey, includedMap);
            }
        }

        return resultMap;
    }

}