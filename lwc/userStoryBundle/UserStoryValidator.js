import WARNING_NO_US_SELECTED from '@salesforce/label/c.USB_WARNING_NO_US_SELECTED';
import WARNING_NO_COMMITS from '@salesforce/label/c.USB_WARNING_NO_COMMITS';
import WARNING_DIFFERENT_ENVIRONMENTS from '@salesforce/label/c.USB_WARNING_DIFFERENT_ENVIRONMENTS';
import WARNING_DIFFERENT_PIPELINES from '@salesforce/label/c.USB_WARNING_DIFFERENT_PIPELINES';

import US_ENVIRONMENT_FIELD from '@salesforce/schema/User_Story__c.Environment__c';
import US_PROJECT_FIELD from '@salesforce/schema/User_Story__c.Project__c';
import US_RELEASE_FIELD from '@salesforce/schema/User_Story__c.Release__c';
import PIPELINE_OBJECT from '@salesforce/schema/Deployment_Flow__c';

export default class UserStoryValidator {
    execute(stories, metadata, fullProfiles, destructiveChanges) {
        const result = [];

        if (stories.length < 2) {
            result.push(WARNING_NO_US_SELECTED);
        } else if (metadata.length === 0 && fullProfiles.length === 0 && destructiveChanges.length === 0) {
            result.push(WARNING_NO_COMMITS);
        } else {
            if (this._differentEnvironmentsIn(stories)) {
                result.push(WARNING_DIFFERENT_ENVIRONMENTS);
            }
            if (this._differentPipelinesIn(stories)) {
                result.push(WARNING_DIFFERENT_PIPELINES);
            }
        }

        return result;
    }

    _differentEnvironmentsIn(stories) {
        const refEnvironment = stories[0][US_ENVIRONMENT_FIELD.fieldApiName];
        return stories.some((story) => story[US_ENVIRONMENT_FIELD.fieldApiName] !== refEnvironment);
    }

    _differentPipelinesIn(stories) {
        const refPipeline = this._getPipelineRelatedTo(stories[0]);
        return stories.some((story) => this._getPipelineRelatedTo(story) !== refPipeline);
    }

    _getPipelineRelatedTo(story) {
        let result;

        const usProjectRel = US_PROJECT_FIELD.fieldApiName.replace('__c', '__r');
        const usReleaseRel = US_RELEASE_FIELD.fieldApiName.replace('__c', '__r');
        const pipelineObj = PIPELINE_OBJECT.objectApiName;

        if (story[usProjectRel] && story[usProjectRel][pipelineObj]) {
            result = story[usProjectRel][pipelineObj];
        } else if (story[usReleaseRel] && story[usReleaseRel][usProjectRel] && story[usReleaseRel][usProjectRel][pipelineObj]) {
            result = story[usReleaseRel][usProjectRel][pipelineObj];
        }

        return result;
    }
}