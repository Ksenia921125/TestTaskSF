@isTest
private class ObjectPermissionTriggerTest {

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

    public static List<Object_Permissions__c> nonexistentOP;
    public static Profile_Group_Object_Permission__c existingPGOP;

    static void initProfilePermissions() {
        existingPGOP = new Profile_Group_Object_Permission__c(
            RecordTypeId        = objectPermissionRecordTypes.get('Profile'),
            Profile_API_Name__c = 'System Administrator',
            Object_API_Name__c  = 'Account'
        );
        insert existingPGOP;

        List<Object_Permissions__c> existingOP = new List<Object_Permissions__c>();
        existingOP.add(
            new Object_Permissions__c(
                Profile_Group_Object_Permission__c = existingPGOP.Id,
                RecordTypeId    = objectPermissionRecordTypes.get('CRUD'),
                Creatable__c    = false,
                Readable__c     = false,
                Updatable__c    = false,
                Deletable__c    = false,
                Modify_All__c   = false,
                View_All__c     = false
            )
        );
        existingOP.add(
            new Object_Permissions__c(
                Profile_Group_Object_Permission__c = existingPGOP.Id,
                RecordTypeId        = objectPermissionRecordTypes.get('FLS'),
                Field_API_Name__c   = 'CreatedById',
                Field_Readable__c   = false,
                Field_Updatable__c  = false
            )
        );
        insert existingOP;

        Profile_Group_Object_Permission__c nonexistentOPforPGOP = new Profile_Group_Object_Permission__c(
            RecordTypeId        = objectPermissionRecordTypes.get('Profile'),
            Profile_API_Name__c = 'System Administrator',
            Object_API_Name__c  = 'Contact'
        );
        insert nonexistentOPforPGOP;

        nonexistentOP = new List<Object_Permissions__c>();
        nonexistentOP.add(
            new Object_Permissions__c(
                Profile_Group_Object_Permission__c = existingPGOP.Id,
                RecordTypeId    = objectPermissionRecordTypes.get('CRUD'),
                Creatable__c    = true,
                Readable__c     = true,
                Updatable__c    = true,
                Deletable__c    = true,
                Modify_All__c   = true,
                View_All__c     = true
            )
        );
        nonexistentOP.add(
            new Object_Permissions__c(
                Profile_Group_Object_Permission__c = existingPGOP.Id,
                RecordTypeId        = objectPermissionRecordTypes.get('FLS'),
                Field_API_Name__c   = 'Id',
                Field_Readable__c   = true,
                Field_Updatable__c  = true
            )
        );
        nonexistentOP.add(
            new Object_Permissions__c(
                Profile_Group_Object_Permission__c = nonexistentOPforPGOP.Id,
                RecordTypeId    = objectPermissionRecordTypes.get('CRUD'),
                Creatable__c    = false,
                Readable__c     = false,
                Updatable__c    = false,
                Deletable__c    = false,
                Modify_All__c   = false,
                View_All__c     = false
            )
        );
        nonexistentOP.add(
            new Object_Permissions__c(
                Profile_Group_Object_Permission__c = nonexistentOPforPGOP.Id,
                RecordTypeId        = objectPermissionRecordTypes.get('FLS'),
                Field_API_Name__c   = 'CreatedById',
                Field_Readable__c   = false,
                Field_Updatable__c  = false
            )
        );
    }

    @isTest static void objectPermissionsForProfile() {
        initProfilePermissions();

        Test.startTest();

        List<Object_Permissions__c> opBeforeInsert = [SELECT Id FROM Object_Permissions__c];

        Database.insert(nonexistentOP, false);

        List<Object_Permissions__c> opAfterInsert = [SELECT Id FROM Object_Permissions__c];
        Integer addedRecords = opAfterInsert.size() - opBeforeInsert.size();
        System.assertEquals(3, addedRecords);

        opAfterInsert = [
            SELECT Id, Creatable__c
            FROM Object_Permissions__c 
            WHERE Profile_Group_Object_Permission__c = :existingPGOP.Id
                AND RecordTypeId = :objectPermissionRecordTypes.get('CRUD')
        ];

        System.assertEquals(1, opAfterInsert.size());
        System.assertEquals(false, opAfterInsert.get(0).Creatable__c);

        Object_Permissions__c opForUpdate = nonexistentOP.get(1);
        opForUpdate.Field_API_Name__c = 'CreatedById';
        try {
            update opForUpdate;
        } catch (Exception e){
            System.assert(e.getMessage().contains(System.Label.Not_unique_record));
        }

        Test.stopTest();
    }

}