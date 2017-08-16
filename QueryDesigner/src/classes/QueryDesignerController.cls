public class QueryDesignerController {

    public class ObjectType {
        String objectTypeName { get; set; }
        List<String> fields { get; set; }
        
        public ObjectType(String objectTypeName, List<String> fields) {
            this.objectTypeName = objectTypeName;
            this.fields = fields;
        }
    }

    public static String getSObjects() {
        List<ObjectType> sObjectsList = new List<ObjectType>();

        for (Schema.SObjectType sObjectType : Schema.getGlobalDescribe().values()) {
            String objType = String.valueOf(sObjectType);
            List<String> fields = getFields(objType);
            sObjectsList.add(new ObjectType(objType,fields));
        }
        return JSON.serialize(sObjectsList);
    }    

    private static List<String> getFields(String sObjectType) {
        Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();
        List<String> fieldsList = new List<String>();
        for (Schema.SObjectField field : fieldMap.values()) {
            fieldsList.add(String.valueOf(field));
        }
        fieldsList.sort();
        return fieldsList;
    }

    @RemoteAction
    public static List<sObject> executeQuery(String query) {
        List<sObject> resultList = Database.query(query);
        return resultList;
    }
}