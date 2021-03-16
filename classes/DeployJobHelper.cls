public with sharing class DeployJobHelper {
    public static void upsertDeployJobs(Set<Id> deploymentIds) {
        List<Step__c> steps = [SELECT id, name, deployment__c FROM Step__c WHERE deployment__c IN :deploymentIds];
        List<Destination_Org__c> dests = [
            SELECT id, deployment__c, To_Org__r.Environment__r.Run_all_tests__c
            FROM Destination_Org__c
            WHERE deployment__c IN :deploymentIds
        ];
        List<Deployment_Job__c> deploymentJobs = new List<Deployment_Job__c>();
        for (Step__c s : steps) {
            for (Destination_Org__c d : dests) {
                if (s.Deployment__c == d.Deployment__c)
                    deploymentJobs.add(new Deployment_Job__c(step__c = s.id, destination_org__c = d.id, external_id__c = s.id + '_' + d.id));
            }
        }
        try {
            Utilities.Secure_DML(
                deploymentJobs,
                Utilities.DML_Action.UPS,
                schema.Sobjecttype.Deployment_Job__c,
                schema.sObjectType.Deployment_Job__c.fields.external_id__c
            );
        } catch (DmlException e) {
            //If we are in visualforce context
            if (ApexPages.currentPage() != null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '' + e));
            }
        }
    }
    public static String updateStatus(Deployment_Job__c dj, Id deploymentId) {
        //get all Deployment jobs for the current Deployment
        List<Deployment_Job__c> deploymentJobs = [
            SELECT Id, Status__c, Step__c, Step__r.Status__c, Destination_Org__c, Destination_Org__r.Status__c
            FROM Deployment_Job__c
            WHERE step__r.deployment__c = :deploymentId
            ORDER BY Destination_Org__c, Step__r.Order__c
        ];

        //map the status of all destination orgs
        Map<Id, String> destinationOrgStatusByIds = new Map<Id, String>();
        for (Deployment_Job__c t : deploymentJobs) {
            destinationOrgStatusByIds.put(t.Destination_Org__c, '');
        }

        for (Id k : destinationOrgStatusByIds.keySet()) {
            destinationOrgStatusByIds.put(k, getDestinationOrgStatus(deploymentJobs, k));
        }

        //define status of the destination org
        Destination_Org__c destinationOrg = new Destination_Org__c(
            Id = dj.destination_org__c,
            Status__c = destinationOrgStatusByIds.get(dj.destination_org__c)
        );
        Utilities.Secure_DML(destinationOrg, Utilities.DML_Action.UPD, schema.Sobjecttype.Destination_Org__c);

        //define status of the step
        Step__c s = new Step__c(Id = dj.step__c);
        String ss = '';
        for (Deployment_Job__c t : deploymentJobs) {
            if (t.Step__c == dj.Step__c) {
                if (t.Status__c == 'Pending') {
                    ss = destinationOrgStatusByIds.get(t.Destination_Org__c);
                    break;
                } else if (t.Status__c == 'Success' && ss == '') {
                    ss = 'Completed Successfully';
                } else if (t.Status__c == 'Failed') {
                    ss = 'Completed with Errors';
                } else if (t.Status__c == 'Cancelled') {
                    ss = 'Cancelled';
                    break;
                }
            }
        }

        s.Status__c = ss;
        Utilities.Secure_DML(s, Utilities.DML_Action.UPD, schema.Sobjecttype.Step__c);

        //define status of the deployment
        Deployment__c d = new Deployment__c(Id = deploymentId);
        String ds = '';
        Boolean isAllcompleted = true;
        Boolean isCancelled = false;
        for (Id k : destinationOrgStatusByIds.keySet()) {
            String destinationOrgStatus = destinationOrgStatusByIds.get(k);
            if (
                destinationOrgStatus == 'In progress' ||
                destinationOrgStatus == 'Pending' ||
                destinationOrgStatus == 'In Progress' ||
                destinationOrgStatus == 'Not started'
            ) {
                ds = 'In progress';
                isAllcompleted = false;
                break;
            } else if (destinationOrgStatus == 'Completed Successfully' && ds == '') {
                ds = 'Completed Successfully';
            } else if (destinationOrgStatus == 'Completed with Errors' && ds != 'Cancelled') {
                ds = 'Completed with Errors';
            } else if (destinationOrgStatus == 'Cancelled') {
                ds = 'Cancelled';
                isCancelled = true;
            }
        }

        if (isAllcompleted) {
            d.Status__c = ds;
            Utilities.Secure_DML(d, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);
        }

        return ds;
    }

    public static Map<Id, String> updateStatus(
        Map<Id, List<Deployment_Job__c>> deploymentJobsByDeploymentIds,
        List<Deployment_Job__c> deploymentJobs
    ) {
        Map<Id, String> destinationOrgStatusByIds = new Map<Id, String>();

        for (Deployment_Job__c deploymentJobRecord : deploymentJobs) {
            destinationOrgStatusByIds.put(deploymentJobRecord.Destination_Org__c, '');
        }

        for (Id destinationOrgId : destinationOrgStatusByIds.keySet()) {
            destinationOrgStatusByIds.put(destinationOrgId, getDestinationOrgStatus(deploymentJobs, destinationOrgId));
        }
        Map<Id, Destination_Org__c> destinationOrgsByIds = new Map<Id, Destination_Org__c>();
        Map<Id, Step__c> stepsByIds = new Map<Id, Step__c>();
        Map<Id, Deployment__c> deploymentsByIds = new Map<Id, Deployment__c>();
        Map<Id, String> deploymentStatusesByIds = new Map<Id, String>();

        for (Id deploymentId : deploymentJobsByDeploymentIds.keySet()) {
            for (Deployment_Job__c deploymentJob : deploymentJobsByDeploymentIds.Get(deploymentId)) {
                //define status of the destination org
                Destination_Org__c destinationOrg = new Destination_Org__c(
                    Id = deploymentJob.Destination_org__c,
                    Status__c = destinationOrgStatusByIds.get(deploymentJob.Destination_org__c)
                );
                destinationOrgsByIds.put(destinationOrg.Id, destinationOrg);

                //define status of the step
                Step__c step = new Step__c(Id = deploymentJob.step__c);
                String newStepStatus = '';
                for (Deployment_Job__c deploymentJobRecord : deploymentJobs) {
                    if (deploymentJobRecord.Step__c == deploymentJob.Step__c) {
                        if (deploymentJobRecord.Status__c == 'Pending') {
                            newStepStatus = destinationOrgStatusByIds.get(deploymentJobRecord.Destination_Org__c);
                            break;
                        } else if (deploymentJobRecord.Status__c == 'Success' && newStepStatus == '') {
                            newStepStatus = 'Completed Successfully';
                        } else if (deploymentJobRecord.Status__c == 'Failed') {
                            newStepStatus = 'Completed with Errors';
                        } else if (deploymentJobRecord.Status__c == 'Cancelled') {
                            newStepStatus = 'Cancelled';
                            break;
                        }
                    }
                }
                if (String.isNotBlank(newStepStatus)) {
                    step.Status__c = newStepStatus;
                }                
                stepsByIds.put(step.Id, step);

                //define status of the deployment
                Deployment__c deployment = new Deployment__c(Id = deploymentId);
                String newDeploymentStatus = '';
                Boolean isAllcompleted = true;
                Boolean isCancelled = false;
                for (Id destinationOrgId : destinationOrgStatusByIds.keySet()) {
                    String destinationOrgStatus = destinationOrgStatusByIds.get(destinationOrgId);
                    if (
                        destinationOrgStatus.toLowerCase() == 'in progress' ||
                        destinationOrgStatus == 'Pending' ||
                        destinationOrgStatus == 'Not started'
                    ) {
                        newDeploymentStatus = 'In progress';
                        isAllcompleted = false;
                        break;
                    } else if (destinationOrgStatus == 'Completed Successfully' && newDeploymentStatus == '') {
                        newDeploymentStatus = 'Completed Successfully';
                    } else if (destinationOrgStatus == 'Completed with Errors' && newDeploymentStatus != 'Cancelled') {
                        newDeploymentStatus = 'Completed with Errors';
                    } else if (destinationOrgStatus == 'Cancelled') {
                        newDeploymentStatus = 'Cancelled';
                        isCancelled = true;
                    }
                }
                if (isAllcompleted) {
                    deployment.Status__c = newDeploymentStatus;
                    deploymentsByIds.put(deployment.Id, deployment);
                }

                deploymentStatusesByIds.put(deploymentId, newDeploymentStatus);
            }
        }

        Utilities.Secure_DML(destinationOrgsByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Destination_Org__c);
        Utilities.Secure_DML(stepsByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Step__c);
        Utilities.Secure_DML(deploymentsByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);
        updateResultRecordRelatedToDeployment(deploymentsByIds);
        return deploymentStatusesByIds;
    }

    private static void updateResultRecordRelatedToDeployment(Map<Id, Deployment__c> deploymentsByIds) {
        List<Result__c> results = [SELECT Id, Deployment__c, End_Time__c, Status__c FROM Result__c WHERE Deployment__c IN :deploymentsByIds.keySet()];

        for (Result__c resultRecord : results) {
            String deploymentStatus = deploymentsByIds.get(resultRecord.Deployment__c).Status__c;
            String resultStatus = deploymentStatus == 'Completed Successfully'
                ? 'Success'
                : deploymentStatus == 'Completed with Errors' ? 'Failed' : 'In progress';
            resultRecord.Status__c = resultStatus;
            resultRecord.End_Time__c = System.now();
        }
        Utilities.Secure_DML(results, Utilities.DML_Action.UPD, schema.Sobjecttype.Result__c);
    }

    public static String getDestinationOrgStatus(List<Deployment_Job__c> deploymentJobs, Id destinationOrgId) {
        String newDestinationOrgStatus = '';
        for (Deployment_Job__c deploymentJobRecord : deploymentJobs) {
            if (deploymentJobRecord.Destination_Org__c == destinationOrgId) {
                if (deploymentJobRecord.Status__c == 'Pending' && deploymentJobRecord.Destination_Org__r.Status__c == 'Not started') {
                    newDestinationOrgStatus = 'Not started';
                    break;
                } else if (
                    (deploymentJobRecord.Status__c == 'Pending' || deploymentJobRecord.Status__c == 'In progress') &&
                    newDestinationOrgStatus != 'Completed with Errors'
                ) {
                    newDestinationOrgStatus = 'In progress';
                    break;
                } else if (deploymentJobRecord.Status__c == 'Success' && newDestinationOrgStatus == '') {
                    newDestinationOrgStatus = 'Completed Successfully';
                } else if (deploymentJobRecord.Status__c == 'Failed') {
                    newDestinationOrgStatus = 'Completed with Errors';
                } else if (deploymentJobRecord.Status__c == 'Cancelled') {
                    newDestinationOrgStatus = 'Cancelled';
                    break;
                }
            }
        }
        return newDestinationOrgStatus;
    }
}