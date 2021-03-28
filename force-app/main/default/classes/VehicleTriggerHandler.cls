public with sharing class VehicleTriggerHandler {

    public static void onBeforeInsert(List<Vehicle__c> insertedVehicles) {
        VehicleTriggerHelper.checkNextMaintenanceDateInsert(insertedVehicles);
    }

    public static void onBeforeUpdate(Map<Id, Vehicle__c> vehiclesNewMap, Map<Id, Vehicle__c> vehiclesOldMap) {
        VehicleTriggerHelper.initDataForMaintenanceProcess(vehiclesNewMap, vehiclesOldMap);
    }

    public static void eonAfterInsert(List<Vehicle__c> insertedVehicles) {
        VehicleTriggerHelper.checkStatusAfterInsert(insertedVehicles);
    }

    public static void onAfterUpdate(Map<Id, Vehicle__c> vehiclesNewMap, Map<Id, Vehicle__c> vehiclesOldMap) {
        VehicleTriggerHelper.checkStatusAfterUpdate(vehiclesNewMap, vehiclesOldMap);
        VehicleTriggerHelper.updateMaintenanceProcess();
        VehicleTriggerHelper.assignMaintenance();
    }
}