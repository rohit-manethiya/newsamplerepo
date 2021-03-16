public with sharing class ReleaseExt {
    public Release__c release {get; set;}
    public Release__c previousRelease {get;set;}
    public VersionWrapper versionWrapper {get;set;}
    public AuxiliaryObject__c lookupAux {get;set;}


    public ReleaseExt(ApexPages.StandardController std) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            std.addFields(new List<String>(Schema.SObjectType.Release__c.fields.getMap().keySet()));
        }

        if (std.getId() != null) {
            release = Utilities.getReleaseById(std.getId());

            // Show Version Missing message
            if(release.Version__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, Label.RELEASE_VERSION_MISSING));
            }
        } else {
            release = new Release__c();
        }
        lookupAux = new AuxiliaryObject__c();

        getPreviousRelease();
    }

    public void getPreviousRelease() {
        List<Release__c> previousReleases;

        if(lookupAux.Release__c == null) {
            if(Schema.sObjectType.Release__c.isQueryable() && Schema.sObjectType.Release__c.isAccessible()) {
                if (release.Project__c != null) {
                    previousReleases = [SELECT Id, Name, Version__c FROM Release__c WHERE Id != :release.Id AND Project__c = :release.Project__c AND Status__c = 'Released' AND Version__c != null ORDER BY Planned_Date__c, CreatedDate DESC LIMIT 1];
                } else {
                    previousReleases = [SELECT Id, Name, Version__c FROM Release__c WHERE Id != :release.Id AND Status__c = 'Released' AND Version__c != null ORDER BY Planned_Date__c, CreatedDate DESC LIMIT 1];
                }
            }
        } else if(previousRelease != null && previousRelease.Id == lookupAux.Release__c) {
            return;
        } else {
            // The lookupAux.Release__c was changed in the UI
            if(Schema.sObjectType.Release__c.isQueryable() && Schema.sObjectType.Release__c.isAccessible()) {
                previousReleases = [SELECT Id, Name, Version__c FROM Release__c WHERE Id = :lookupAux.Release__c LIMIT 1];
            }
        }
        
        if (previousReleases.size() > 0) {
            previousRelease = previousReleases[0];
            lookupAux.Release__c = previousRelease.Id;
        }
        getVersiondetails();
    }

    public void getVersionDetails() {
        // Default release number values
        String major = '1';
        String minor = '1.1';
        String patch = '1.0.1';
        String newVersion = '1';
        String prefix = '';
        String suffix = '';

        if(previousRelease != null) {
            String previousVersion = previousRelease.Version__c;
            try {
                List<String> versionSegments = new List<String>();

                String regex = '(.*?)(?:(?<major>\\d+)\\.)?(?:(?<minor>\\d+)\\.)?(?:(?<patch>\\d+))(.*)';
                Pattern p = Pattern.compile(regex);
                Matcher pm = p.matcher(previousVersion);
                if (pm.matches()) {
                    for (Integer i = 1; i <= pm.groupCount(); i++) {
                        System.debug(pm.group(i));
                        // Check if this group is blank after removing all numbers. If it is, then its content is numbers only, therefore it should be assigned to the version segments.
                        if(pm.group(i) != null && !String.isEmpty(pm.group(i)) && String.isBlank(pm.group(i).replaceAll('[0-9]', ''))) {
                            versionSegments.add(pm.group(i));
                        } else if(i == 1) {
                            prefix = pm.group(i);
                        } else if(i == 5) {
                            suffix = pm.group(i);
                        }
                    }
                } 

                if(versionSegments.size() >= 1 && versionSegments[0] != null) {
                    major = String.valueOf(Integer.valueOf(versionSegments[0]) + 1);
                }

                minor = versionSegments[0] + '.1';
                if(versionSegments.size() >= 2 && versionSegments[1] != null && Integer.valueOf(versionSegments[1]) != null) {
                    minor = versionSegments[0] + '.' + String.valueOf(Integer.valueOf(versionSegments[1]) + 1);
                }

                patch = versionSegments[0] + '.' + (versionSegments.size() >= 2 && versionSegments[1] != null ? versionSegments[1] : '0') + '.1';
                if(versionSegments.size() >= 3 && versionSegments[2] != null && Integer.valueOf(versionSegments[2]) != null) {
                    patch = versionSegments[0] + '.' + versionSegments[1] + '.' + String.valueOf(Integer.valueOf(versionSegments[2]) + 1);
                }
            } catch (Exception e) {
                System.debug('#### Could not parse previous release version');
            }
        }

        if(!String.isBlank(release.Version__c)) {
            // If the Release Version is already defined, assign it as the newVersion value
            newVersion = release.Version__c;
        } else if(major != null) {
            newVersion = prefix + major + suffix;
        }

        versionWrapper = new versionWrapper(major, minor, patch, newVersion, prefix, suffix);
    }

    public class VersionWrapper {
        public String major {get;set;}
        public String minor {get;set;}
        public String patch {get;set;}
        public String newVersion {get;set;}
        public String prefix {get;set;}
        public String suffix {get;set;}

        public VersionWrapper(String major, String minor, String patch, String newVersion, String prefix, String suffix) {
            this.major = major;
            this.minor = minor;
            this.patch = patch;
            this.newVersion = newVersion;
            this.prefix = prefix;
            this.suffix = suffix;
        }
    }

    public PageReference updateRelease() {
        ApexPages.getMessages().clear();
        release.Version__c = versionWrapper.newVersion;

        if(release.Version__c != null && release.Version__c.containsWhitespace()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Version_Format_Message));
            return null;
        }

        PageReference retPage = new Apexpages.Standardcontroller(release).view();
        retPage.setRedirect(true);

        try {
            Utilities.Secure_DML(release, Utilities.DML_Action.UPD, Schema.SObjectType.Release__c);
            return retPage;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.ERROR + ': ' + e.getMessage()));
            return null;
        }
    }
}