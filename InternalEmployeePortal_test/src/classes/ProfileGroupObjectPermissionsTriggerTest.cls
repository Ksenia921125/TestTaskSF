@isTest
private class ProfileGroupObjectPermissionsTriggerTest {

    public static List<Profile_Group_Object_Permission__c> objectsList;

    static void init() {
        objectsList = new List<Profile_Group_Object_Permission__c>();

        RecordType recType = [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'Profile_Group_Object_Permission__c'
            AND DeveloperName = 'Profile'
            LIMIT 1
        ];

        insert new Profile_Group_Object_Permission__c(
            RecordTypeId = recType.Id,
            Profile_API_Name__c = 'System Administrator',
            Object_API_Name__c = 'Account'
        );

        objectsList.add(
            new Profile_Group_Object_Permission__c(
                RecordTypeId = recType.Id,
                Profile_API_Name__c = 'System Administrator',
                Object_API_Name__c = 'Account'
            )
        );

        objectsList.add(
            new Profile_Group_Object_Permission__c(
                RecordTypeId = recType.Id,
                Profile_API_Name__c = 'Standard User',
                Object_API_Name__c = 'Contact'
            )
        );
    }

    @isTest static void testInsert() {
        init();

        Test.startTest();

        List<Profile_Group_Object_Permission__c> actualBeforeInsert = [
            SELECT Profile_API_Name__c, Object_API_Name__c
            FROM Profile_Group_Object_Permission__c
        ];
        System.assert(!actualBeforeInsert.isEmpty());

        Database.insert(objectsList, false);

        List<Profile_Group_Object_Permission__c> actualAfterInsert = [
            SELECT Profile_API_Name__c, Object_API_Name__c
            FROM Profile_Group_Object_Permission__c
        ];
        System.assertNotEquals((actualAfterInsert.size() - actualBeforeInsert.size()), objectsList.size());

        Test.stopTest();
    }

    @isTest static void testUpdate() {
        init();
        Database.insert(objectsList, false);

        Test.startTest();

        Profile_Group_Object_Permission__c pgopForUpdate = [
            SELECT Profile_API_Name__c, Object_API_Name__c
            FROM Profile_Group_Object_Permission__c
            WHERE Object_API_Name__c = 'Account'
            LIMIT 1
        ];

        pgopForUpdate.Profile_API_Name__c = 'Standard User';
        pgopForUpdate.Object_API_Name__c = 'Contact';

        Database.update(pgopForUpdate, false);

        List<Profile_Group_Object_Permission__c> actualAfterUpdate = [
            SELECT Profile_API_Name__c, Object_API_Name__c
            FROM Profile_Group_Object_Permission__c
            WHERE Object_API_Name__c = 'Account'
        ];

        System.assertEquals(1, actualAfterUpdate.size());
        System.assertEquals('System Administrator', actualAfterUpdate.get(0).Profile_API_Name__c);

        Test.stopTest();
    }
}