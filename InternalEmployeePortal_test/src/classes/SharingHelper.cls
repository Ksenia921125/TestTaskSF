public with sharing class SharingHelper {

  public static void shareRecords(String sObjectName, String fieldName, List<sObject> oldRecords, List<sObject> newRecords) {

    String objectShareType = sObjectName.contains('__c') ? sObjectName.replace('__c', '__Share') : sObjectName + 'Share';

    try {
      Database.query('SELECT Id FROM ' + objectShareType + ' LIMIT 1');
    } catch(Exception e) {
      return;
    }

    // Map<Contact.Id, User.Id>
    Map<String, String> sharingUsers = new Map<String, String>();
    Map<String, String> forDelete = new Map<String, String>();

    if (oldRecords == null) {
      for (sObject rec : newRecords) {
        sharingUsers.put(String.valueOf(rec.get('Id')), String.valueOf(rec.get(fieldName)));
      }
    } else {
      Map<Id, sObject> oldRecMap = new Map<Id, sObject>(oldRecords);
      
      for (sObject recNew : newRecords) {
        String recNewId = String.valueOf(recNew.get('Id'));

        if (oldRecMap.containsKey(recNewId)) {
          sObject recOld = oldRecMap.get(recNewId);

          if (recOld.get(fieldName) != recNew.get(fieldName)) {
            sharingUsers.put(recNewId, String.valueOf(recNew.get(fieldName)));
            forDelete.put(String.valueOf(recOld.get('Id')), String.valueOf(recOld.get(fieldName)));
          }
        }
      }
    }

    Map<String, String> sharingGroups = getSharingGroups(sharingUsers);

    if (!forDelete.isEmpty()) {
      List<String> delRec = new List<String>();
      delRec.addAll(forDelete.values());
      delRec.addAll(getSharingGroups(forDelete).values());
      delete Database.query('SELECT Id FROM ' + objectShareType + ' WHERE UserOrGroupId IN :delRec');
    }

    List<sObject> sharingRecords = getShares(sObjectName, sharingUsers);
    sharingRecords.addAll(getShares(sObjectName, sharingGroups));

    insert sharingRecords;
  }

  // Map<Contact.Id, User.Id> -> Map<Contact.Id, Group.Id>
  private static Map<String, String> getSharingGroups(Map<String, String> sharingUsers) {
    List<String> namesForGroup = new List<String>();
    for (String g : sharingUsers.values()) {
      namesForGroup.add('ManagerUp_' + g);
    }

    Map<String, String> groups = new Map<String, String>();
    for (Group g : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :namesForGroup]) {
      groups.put(g.DeveloperName, g.Id);
    }

    Map<String, String> sharingGroups = new Map<String, String>();
    for (String recId : sharingUsers.keySet()) {
      sharingGroups.put(recId, groups.get('ManagerUp_' + sharingUsers.get(recId)));
    }

    return sharingGroups;
  }

  private static List<sObject> getShares(String sObjectName, Map<String, String> usersOrGroups) {
    Boolean isCustom = sObjectName.contains('__c');
    Type objectShareType = Type.forName(isCustom ? sObjectName.replace('__c', '__Share') : sObjectName + 'Share');
    List<sObject> shares = new List<sObject>();
    sObject shrObject;

    for (String recId : usersOrGroups.keySet()) {
      shrObject = (sObject) objectShareType.newInstance();

      shrObject.put(isCustom ? 'AccessLevel' : sObjectName + 'AccessLevel', 'Edit');
      shrObject.put(isCustom ? 'ParentId' : sObjectName + 'Id', recId);
      shrObject.put('RowCause', isCustom ? 'ManagerSharing__c' : 'Manual');
      shrObject.put('UserOrGroupId', usersOrGroups.get(recId));

      shares.add(shrObject);
    }
    return shares;
  }

}