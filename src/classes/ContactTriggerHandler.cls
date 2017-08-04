public class ContactTriggerHandler {
  
  public static void sharingRecords(String sObjectName, String fieldName, List<Contact> oldContacts, List<Contact> newContacts) {
    
    String objectShareType = sObjectName.contains('__c') ? sObjectName.replace('__c', '__Share') : sObjectName + 'Share';

    try {
      Database.query('SELECT Id FROM ' + objectShareType + ' LIMIT 1');      
    } catch(Exception e) {
      return;
    }

    // Map<Contact.Id, User.Id>
    Map<String, String> sharingUsers = new Map<String, String>();
    Map<String, String> forDelete = new Map<String, String>();

    if (oldContacts == null || oldContacts.isEmpty()) {
      for (sObject c : newContacts) {
        sharingUsers.put(String.valueOf(c.get('Id')), String.valueOf(c.get(fieldName)));
      }
    } else {
      for (sObject cOld : oldContacts) {
        for (sObject cNew : newContacts) {
          if (cOld.get(fieldName) != cNew.get(fieldName)) {
            sharingUsers.put(String.valueOf(cNew.get('Id')), String.valueOf(cNew.get(fieldName)));
            forDelete.put(String.valueOf(cOld.get('Id')), String.valueOf(cOld.get(fieldName)));
          }
        }
      }
    }

    Map<String, String> sharingGroups = getSharingGroups(sharingUsers);

    if (!forDelete.isEmpty()) {
      forDelete.putall(getSharingGroups(forDelete));
      List<sObject> deleteRecords = Database.query('SELECT Id FROM ' + objectShareType + ' WHERE UserOrGroupId = :forDelete.values()');
      Database.delete(deleteRecords, false);
    }

    List<sObject> contactShrs = getShares(sObjectName, sharingUsers);
    contactShrs.addAll(getShares(sObjectName, sharingGroups));

    Database.SaveResult[] lsr = Database.insert(contactShrs, false);
  }

  // Map<Contact.Id, User.Id> -> Map<Contact.Id, Group.Id>
  private static Map<String, String> getSharingGroups(Map<String, String> sharingUsers) {
    List<String> namesForGroup = new List<String>();
    for (String g : sharingUsers.values()) {
      namesForGroup.add('ManagerUp_' + g);
    }

    Map<String, String> groups = new Map<String, String>();
    for (Group g : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :namesForGroup]) {
      groups.put(g.DeveloperName, g.Id);
    }

    Map<String, String> sharingGroups = new Map<String, String>();
    for (String recId : sharingUsers.keySet()) {
      sharingGroups.put(recId, groups.get('ManagerUp_' + sharingUsers.get(recId)));
    }

    return sharingGroups;
  }

  private static List<sObject> getShares(String sObjectName, Map<String, String> users) {
    Type objectShareType = Type.forName(sObjectName.contains('__c') ? sObjectName.replace('__c', '__Share') : sObjectName + 'Share');
    List<sObject> shares = new List<sObject>();
    sObject shrForUser;

    for (String recId : users.keySet()) {
      shrForUser = (sObject) objectShareType.newInstance();

      shrForUser.put(sObjectName.contains('__c') ? 'AccessLevel' : sObjectName + 'AccessLevel', 'Edit');
      shrForUser.put(sObjectName.contains('__c') ? 'ParentId' : sObjectName + 'Id', recId);
      shrForUser.put('RowCause', 'Manual');
      shrForUser.put('UserOrGroupId', users.get(recId));

      shares.add(shrForUser);
    }
    return shares;
  }

}