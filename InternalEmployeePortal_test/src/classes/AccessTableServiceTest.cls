@isTest
private class AccessTableServiceTest {

    public static List<Profile_Group_Object_Permission__c> errorList;
    public static List<Profile_Group_Object_Permission__c> correctList;

    private static Map<String, Id> objectPermissionRecordTypes {
        get {
            if (objectPermissionRecordTypes == null) {
                objectPermissionRecordTypes = new Map<String, Id>();
                
                List<RecordType> recordTypes = [
                    SELECT Id, DeveloperName
                    FROM RecordType
                    WHERE SobjectType = 'Object_Permissions__c'
                        OR SobjectType = 'Profile_Group_Object_Permission__c'
                    LIMIT 6
                ];

                for (RecordType rec : recordTypes) {
                    objectPermissionRecordTypes.put(rec.DeveloperName, rec.Id);
                }
            }

            return objectPermissionRecordTypes;
        }
    }


    static void initProfilesObjectPermission() {
        errorList = new List<Profile_Group_Object_Permission__c>();
        errorList.add(
            new Profile_Group_Object_Permission__c(
                RecordTypeId        = objectPermissionRecordTypes.get('Profile'),
                Profile_API_Name__c = 'System Administrator',
                Object_API_Name__c  = 'Object_Permissions__c'
            )
        );
        errorList.add(
            new Profile_Group_Object_Permission__c(
                RecordTypeId        = objectPermissionRecordTypes.get('Profile'),
                Profile_API_Name__c = 'ABC',
                Object_API_Name__c  = 'Object_Permissions__c'
            )
        );

        correctList = new List<Profile_Group_Object_Permission__c>();
        correctList.add(
            new Profile_Group_Object_Permission__c(
                RecordTypeId        = objectPermissionRecordTypes.get('Profile'),
                Profile_API_Name__c = 'System Administrator',
                Object_API_Name__c  = 'Account'
            )
        );
        correctList.add(
            new Profile_Group_Object_Permission__c(
                RecordTypeId        = objectPermissionRecordTypes.get('Profile'),
                Profile_API_Name__c = 'Standard User',
                Object_API_Name__c  = 'Account'
            )
        );
    }

    static void initGroupsObjectPermission() {
        errorList = new List<Profile_Group_Object_Permission__c>();
        errorList.add(
            new Profile_Group_Object_Permission__c(
                RecordTypeId        = objectPermissionRecordTypes.get('Group'),
                Group_API_Name__c   = 'ManagerUp_1',
                Object_API_Name__c  = 'Object_Permissions__c'
            )
        );
        errorList.add(
            new Profile_Group_Object_Permission__c(
                RecordTypeId        = objectPermissionRecordTypes.get('Group'),
                Group_API_Name__c   = 'ABC',
                Object_API_Name__c  = 'Object_Permissions__c'
            )
        );

        correctList = new List<Profile_Group_Object_Permission__c>();
        correctList.add(
            new Profile_Group_Object_Permission__c(
                RecordTypeId        = objectPermissionRecordTypes.get('Group'),
                Group_API_Name__c   = 'EasternSalesTeamA',
                Object_API_Name__c  = 'Account'
            )
        );
    }

    @isTest static void addProfilesObjectPermissions() {
        initProfilesObjectPermission();

        Test.startTest();

        List<Profile_Group_Object_Permission__c> notAdded = AccessTableService.addProfileObjectPermissions(errorList);
        List<Profile_Group_Object_Permission__c> actualEList = [SELECT Id FROM Profile_Group_Object_Permission__c];

        System.assertEquals(1, notAdded.size());

        notAdded = AccessTableService.addProfileObjectPermissions(correctList);
        System.assertEquals(0, notAdded.size());

        List<Profile_Group_Object_Permission__c> actualCList = [SELECT Id, Object_API_Name__c FROM Profile_Group_Object_Permission__c];
        System.assertEquals(correctList.size(), (actualCList.size() - actualEList.size()));

        Profile_Group_Object_Permission__c profileObject = actualCList.get(0);
        Integer fieldsInSchema = Schema.getGlobalDescribe().get(profileObject.Object_API_Name__c).getDescribe().fields.getMap().values().size();
        Integer flsRecordsCount = [
            SELECT Field_API_Name__c
            FROM Object_Permissions__c
            WHERE Profile_Group_Object_Permission__c = :profileObject.Id
                AND RecordTypeId = :objectPermissionRecordTypes.get('FLS')
        ].size();
        System.assertEquals(fieldsInSchema, flsRecordsCount);

        List<Object_Permissions__c> crudPermission = [
            SELECT Creatable__c, Deletable__c
            FROM Object_Permissions__c
            WHERE Profile_Group_Object_Permission__c = :profileObject.Id
                AND RecordTypeId = :objectPermissionRecordTypes.get('CRUD')
        ];
        System.assertEquals(1, crudPermission.size());

        Test.stopTest();
    }

    @isTest static void addGroupsObjectPermissions() {
        initGroupsObjectPermission();

        Test.startTest();

        List<Profile_Group_Object_Permission__c> notAdded = AccessTableService.addGroupObjectPermissions(errorList);
        System.assertEquals(errorList.size(), notAdded.size());

        notAdded = AccessTableService.addGroupObjectPermissions(correctList);
        System.assert(notAdded.isEmpty());

        List<Object_Permissions__c> objectPermissions = [
            SELECT Id
            FROM Object_Permissions__c
            WHERE RecordTypeId = :objectPermissionRecordTypes.get('OwnerSharing')
                OR RecordTypeId = :objectPermissionRecordTypes.get('OtherSharing')
        ];
        System.assertEquals(2, objectPermissions.size());

        Test.stopTest();
    }
}