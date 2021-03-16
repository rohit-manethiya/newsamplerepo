import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, unregisterAllListeners } from 'c/copadoCorePubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

// Import aura enabled apex methods
import getPickListValues from '@salesforce/apex/ADD_RecordMatchingFormulaOperations.getPickListValues';
import getOrgObjects from '@salesforce/apex/ADD_RecordMatchingFormulaOperations.getOrgObjects';
import getRecordMatchingFormulas from '@salesforce/apex/ADD_RecordMatchingFormulaOperations.getRecordMatchingFormulas';

// Import custom labels
import objectDetails from '@salesforce/label/c.Object_Details';
import formulaConfiguration from '@salesforce/label/c.Record_Matching_Formula_Configuration';
import configurationHelpText from '@salesforce/label/c.Record_Matching_Formula_Configuration_Help_Text';
import objectFieldHelpText from '@salesforce/label/c.Object_Field_Help_Text';
import formula from '@salesforce/label/c.Formula';
import formulaErrorTitle from '@salesforce/label/c.Record_Matching_Formula_Error_Title';
import duplicateObjectErrorMessage from '@salesforce/label/c.Record_Matching_Formula_Duplicate_Error';

// Import Record Matching Formula Fields
import RECORD_MATCHING_FORMULA from '@salesforce/schema/Record_Matching_Formula__c';
import RECORD_ID from '@salesforce/schema/Record_Matching_Formula__c.Id';
import RECORD_NAME from '@salesforce/schema/Record_Matching_Formula__c.Name';
import CONFIGURATION_SOURCE_ORG from '@salesforce/schema/Record_Matching_Formula__c.Configuration_Source_Org__c';
import OBJECT from '@salesforce/schema/Record_Matching_Formula__c.Object__c';
import HASH_FORMULA from '@salesforce/schema/Record_Matching_Formula__c.Hash_Formula__c';
import FIELD_1 from '@salesforce/schema/Record_Matching_Formula__c.Field_1__c';
import FIELD_2 from '@salesforce/schema/Record_Matching_Formula__c.Field_2__c';
import FIELD_3 from '@salesforce/schema/Record_Matching_Formula__c.Field_3__c';

export default class AddRecordTypeMatchingBody extends LightningElement {
    @api recordId;
    @wire(CurrentPageReference) pageRef;
    data = {};
    @track filterDatas = [];
    savedFilterValuesByOrder = {};
    filterableFieldsByObjectName = {};
    mainObjectApiName;
    fieldTypesByFieldNames;
    referenceObjectsByReferenceFields;
    selectedObject;
    orgObjects;
    @track disableSourceOrgInput = false;
    @track disableObjectInput = false;
    @track showObjectInputAsPicklist = false;

    // Expose the object fields to use in the template
    recordMatchingObjectFields = {
        RECORD_MATCHING_FORMULA,
        CONFIGURATION_SOURCE_ORG,
        OBJECT,
        HASH_FORMULA
    };

    // Expose the labels to use in the template.
    label = {
        objectDetails,
        formulaConfiguration,
        configurationHelpText,
        objectFieldHelpText,
        formula,
        formulaErrorTitle,
        duplicateObjectErrorMessage
    };

    connectedCallback() {
        // if record id is undefined, it means the page is opened by clicking new from standard layout.
        if (this.recordId) {
            this.retrieveRecordMatchingFormulaRecord();
        } else {
            this.dispatchSpinnerEvent(true);
        }

        // subscribe to refreshDiagramClicked event
        registerListener('saveFormulaClickedEvent', this.recordDMLOperations, this);
    }

    disconnectedCallback() {
        // unsubscribe from saveFormulaClickedEvent event
        unregisterAllListeners(this);
    }

    retrieveRecordMatchingFormulaRecord() {
        // apex method returns the record information and assigning them to this.data
        getRecordMatchingFormulas({ recordId: this.recordId })
            .then((result) => {
                if (result && result.length > 0) {
                    this.data = result[0];

                    // to disable source org and object fields checkiong if conditions are met
                    if (this.data[RECORD_ID.fieldApiName] && this.data[CONFIGURATION_SOURCE_ORG.fieldApiName]) {
                        this.disableSourceOrgInput = true;
                    }
                    if (this.data[RECORD_ID.fieldApiName] && this.data[OBJECT.fieldApiName]) {
                        this.disableObjectInput = true;
                    }

                    // dispatch event for parent lwc component, in order to update name of the record on the header lwc
                    const selectedEvent = new CustomEvent('updaterecordmatchingname', {
                        detail: this.data.Name
                    });
                    this.dispatchEvent(selectedEvent);

                    // call apex method to get object fields by doing callout to the backend and populate filters with the response
                    this.doCalloutToPopulatePicklistValues();
                }
            })
            .catch((error) => {
                this.dispatchSpinnerEvent(true);
                this.showToastMessage('Application Error', error, 'error', 'dismissable');
            });
    }

    async doCalloutToPopulatePicklistValues() {
        // apex method returns the given object fields as options of the main filters
        getPickListValues({
            orgId: this.data[CONFIGURATION_SOURCE_ORG.fieldApiName],
            mainObject: this.data[OBJECT.fieldApiName]
        })
            .then((result) => {
                // parse the string result
                const parsedData = JSON.parse(result);
                if (parsedData.errors.length > 0) {
                    parsedData.errors.forEach((error) => {
                        this.showToastMessage('Application Error', error, 'error', 'dismissable');
                    });
                    this.dispatchSpinnerEvent(true);
                }
                if (parsedData.options.length > 0) {
                    this.filterableFieldsByObjectName[this.data[OBJECT.fieldApiName]] = parsedData.options;
                    this.mainObjectApiName = this.data[OBJECT.fieldApiName];
                    this.fieldTypesByFieldNames = parsedData.fieldTypesByNames;
                    this.referenceObjectsByReferenceFields = parsedData.referenceObjectsByReferenceFields;

                    // if the mode is editting the record, we might have already filter value in the record fields, so checking them first of all
                    this.prePopulatePicklistValues();

                    // populate filterdataitem and add them into filters array to send infromation to child filter lwc
                    this.populateFilterData();
                }
            })
            .catch((error) => {
                this.dispatchSpinnerEvent(true);
                this.showToastMessage('Application Error', error, 'error', 'dismissable');
            });
    }

    prePopulatePicklistValues() {
        // This is when you edit the existing record matching formula reads the value from the field and assigning them to the this.data variable
        if (this.data[FIELD_1.fieldApiName] !== null) {
            this.savedFilterValuesByOrder[1] = this.data[FIELD_1.fieldApiName];
        }
        if (this.data[FIELD_2.fieldApiName] !== null) {
            this.savedFilterValuesByOrder[2] = this.data[FIELD_2.fieldApiName];
        }
        if (this.data[FIELD_3.fieldApiName] !== null) {
            this.savedFilterValuesByOrder[3] = this.data[FIELD_3.fieldApiName];
        }
    }

    populateFilterData() {
        // this can not be done in for loop, because every row should be populated once the previous row values are populated. Thats why once we get the response we do second callout to populate next row inside respose of promise. We have 3 filter so it is doing promise 3 times.
        this.getFilterDataItemValues(1).then((response) => {
            this.filterDatas.push(response);
            this.getFilterDataItemValues(2).then((response) => {
                this.filterDatas.push(response);
                this.getFilterDataItemValues(3).then((response) => {
                    this.filterDatas.push(response);
                    this.dispatchSpinnerEvent(true);
                });
            });
        });
    }

    getFilterDataItemValues(index) {
        return new Promise((resolve, reject) => {
            let splittedFieldValue = this.savedFilterValuesByOrder[index] ? this.savedFilterValuesByOrder[index].split('.') : [];
            let selectedValue = splittedFieldValue[0] || '';
            const secondSelectedValue = splittedFieldValue[1] || '';
            if (secondSelectedValue) {
                selectedValue = this.changeRelationshipNameByFieldName(selectedValue);
            }

            // creating filterDataItem object to store necessary information for child filter lwc
            let filterDataItem = {
                order: index,
                mainFilterOptions: this.filterableFieldsByObjectName[this.mainObjectApiName],
                selectedValue: selectedValue,
                secondFilterOptions: [],
                secondSelectedValue: secondSelectedValue,
                showSecondFilterPicklist: splittedFieldValue.length > 1
            };

            // if splitted value is equal to sum of two field, we need to make second callout to populate second object fields filter
            if (splittedFieldValue.length > 1) {
                // reference objects can be more than one, for example OwnerID returns (Groud,User), in that case for now we chose User, otherwise always getting the first object in the list
                const referenceObjects = this.referenceObjectsByReferenceFields[filterDataItem.selectedValue];
                const userSelectedAsParent = referenceObjects.includes('User');
                const newObjectAPIName = userSelectedAsParent ? 'User' : referenceObjects[0];

                // if we already have the callout for the selected object before, we will use the information from the already created map, in order to avoid doing lots of callout
                const filterableFields = this.filterableFieldsByObjectName[newObjectAPIName];
                if (filterableFields) {
                    filterDataItem.secondFilterOptions = filterableFields;
                    filterDataItem.showSecondFilterPicklist = true;
                    resolve(filterDataItem);
                } else {
                    // call apex method to get object fields by doing callout to the backend and populate filters with the response
                    this.doCalloutToPopulateSecondRelationPicklistValues(filterDataItem, newObjectAPIName).then((response) => {
                        filterDataItem.secondFilterOptions = response.secondFilterOptions;
                        filterDataItem.showSecondFilterPicklist = response.showSecondFilterPicklist;
                        resolve(filterDataItem);
                    });
                }
            } else {
                resolve(filterDataItem);
            }
        });
    }

    // converts a relationship name (e.g. Account__r) into a valid field name to match available fields in the list
    changeRelationshipNameByFieldName(relationshipName) {
        let result;
        if (relationshipName.endsWith('__r')) {
            result = relationshipName.replace('__r', '__c');
        } else {
            result = relationshipName + 'Id';
        }
        // check if it is really a reference, if not, leave as is
        const referenceObjects = this.referenceObjectsByReferenceFields[result];
        if (!referenceObjects || referenceObjects.length === 0) {
            result = relationshipName;
        }
        return result;
    }

    async doCalloutToPopulateSecondRelationPicklistValues(filterDataItem, relationObjectAPIName, updateSpinner) {
        return new Promise((resolve, reject) => {
            // apex method returns the given object fields as options of the second filters
            getPickListValues({
                orgId: this.data[CONFIGURATION_SOURCE_ORG.fieldApiName],
                mainObject: relationObjectAPIName
            })
                .then((result) => {
                    // parse the string result
                    const parsedData = JSON.parse(result);
                    if (parsedData.errors.length > 0) {
                        parsedData.errors.forEach((error) => {
                            this.showToastMessage('Application Error', error, 'error', 'dismissable');
                        });
                        this.dispatchSpinnerEvent(true);
                    }
                    if (parsedData.options.length > 0) {
                        this.filterableFieldsByObjectName[relationObjectAPIName] = parsedData.options;
                        filterDataItem.secondFilterOptions = this.filterableFieldsByObjectName[relationObjectAPIName];
                        filterDataItem.showSecondFilterPicklist = true;

                        if (updateSpinner) {
                            this.dispatchSpinnerEvent(true);
                        }
                    }
                    resolve(filterDataItem);
                })
                .catch((error) => {
                    this.showToastMessage('Application Error', error, 'error', 'dismissable');
                    this.dispatchSpinnerEvent(true);
                    reject(error);
                });
        });
    }

    dispatchSpinnerEvent(value) {
        // dispatch event for parent lwc component, in order to update spinner
        const selectedEvent = new CustomEvent('updatespinner', {
            detail: value
        });
        this.dispatchEvent(selectedEvent);
    }

    showToastMessage(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    handleHashValueChange(event) {
        this.data[HASH_FORMULA.fieldApiName] = event.detail.checked;
    }

    handleRemovePicklistFields(event) {
        // the event is triggered from child filter lwc, event contains two parameter (order, showSecondFilterPicklist) which is populated at child lwc, so we are assigning them to necessary values here
        const filterDataItem = this.filterDatas.find((element) => element.order === event.detail.order);
        filterDataItem.showSecondFilterPicklist = event.detail.showSecondFilterPicklist;

        if (event.detail.order === 1) {
            this.data[FIELD_1.fieldApiName] = '';
        } else if (event.detail.order === 2) {
            this.data[FIELD_2.fieldApiName] = '';
        } else if (event.detail.order === 3) {
            this.data[FIELD_3.fieldApiName] = '';
        }
    }

    handleSecondChangePicklistFields(event) {
        const filterDataItem = this.filterDatas.find((element) => element.order === event.detail.order);
        filterDataItem.secondSelectedValue = event.detail.selectedFilterValue;
        let firstPicklistValue = filterDataItem.selectedValue;
        firstPicklistValue = this.changeFieldNameByRelationshipName(firstPicklistValue);
        if (filterDataItem.secondSelectedValue !== '--None--' && event.detail.order === 1) {
            this.data[FIELD_1.fieldApiName] = firstPicklistValue + '.' + filterDataItem.secondSelectedValue;
        } else if (filterDataItem.secondSelectedValue !== '--None--' && event.detail.order === 2) {
            this.data[FIELD_2.fieldApiName] = firstPicklistValue + '.' + filterDataItem.secondSelectedValue;
        } else if (filterDataItem.secondSelectedValue !== '--None--' && event.detail.order === 3) {
            this.data[FIELD_3.fieldApiName] = firstPicklistValue + '.' + filterDataItem.secondSelectedValue;
        }
    }

    // converts a field name (e.g. AccountId) into a valid relationship name to query a field from that object (e.g. Account.Name)
    changeFieldNameByRelationshipName(fieldName) {
        let result = fieldName;
        // check the field is a reference
        const referenceObjects = this.referenceObjectsByReferenceFields[fieldName];
        if (referenceObjects && referenceObjects.length > 0) {
            if (fieldName.endsWith('Id')) {
                result = fieldName.substring(0, fieldName.lastIndexOf('Id'));
            } else {
                result = fieldName.replace('__c', '__r');
            }
        }
        // it is not a relationship
        return result;
    }

    handleChangePicklistFields(event) {
        const filterDataItem = this.filterDatas.find((element) => element.order === event.detail.order);
        filterDataItem.selectedValue = event.detail.selectedFilterValue;

        if (event.detail.order === 1) {
            this.data[FIELD_1.fieldApiName] = filterDataItem.selectedValue === '--None--' ? '' : filterDataItem.selectedValue;
        } else if (event.detail.order === 2) {
            this.data[FIELD_2.fieldApiName] = filterDataItem.selectedValue === '--None--' ? '' : filterDataItem.selectedValue;
        } else if (event.detail.order === 3) {
            this.data[FIELD_3.fieldApiName] = filterDataItem.selectedValue === '--None--' ? '' : filterDataItem.selectedValue;
        }

        const selectedFieldType = this.fieldTypesByFieldNames[filterDataItem.selectedValue];
        if (selectedFieldType && selectedFieldType === 'reference') {
            const referenceObjects = this.referenceObjectsByReferenceFields[filterDataItem.selectedValue];
            const userSelectedAsParent = referenceObjects.includes('User');
            const newObjectAPIName = userSelectedAsParent ? 'User' : referenceObjects[0];
            if (this.filterableFieldsByObjectName[newObjectAPIName]) {
                filterDataItem.secondFilterOptions = this.filterableFieldsByObjectName[newObjectAPIName];
                filterDataItem.showSecondFilterPicklist = true;
            } else {
                this.dispatchSpinnerEvent(false);
                this.doCalloutToPopulateSecondRelationPicklistValues(filterDataItem, newObjectAPIName, true);
            }
        } else {
            filterDataItem.secondFilterOptions = [];
            filterDataItem.secondSelectedValue = '';
            filterDataItem.showSecondFilterPicklist = false;
        }
    }

    handleObjectChange(event) {
        const selectedLabel = event.target.options.find((opt) => opt.value === event.detail.value).label;
        if (event.detail.value) {
            this.dispatchSpinnerEvent(false);
            this.filterDatas = [];
            this.data[OBJECT.fieldApiName] = event.detail.value;
            this.data[RECORD_NAME.fieldApiName] = selectedLabel + ' ' + this.label.formula;
            this.data[FIELD_1.fieldApiName] = '';
            this.data[FIELD_2.fieldApiName] = '';
            this.data[FIELD_3.fieldApiName] = '';
            this.doCalloutToPopulatePicklistValues();
        }
    }

    handleChangeOrg(event) {
        // clear the previous org object list
        this.orgObjects = null;
        // since it is lookup, the value returned with event.detail.value[0]
        if (event.detail.value[0]) {
            this.dispatchSpinnerEvent(false);
            this.data[CONFIGURATION_SOURCE_ORG.fieldApiName] = event.detail.value[0];
            this.doCalloutToPopulateObjects(event.detail.value[0]);
        }
    }

    async doCalloutToPopulateObjects(organizationId) {
        getOrgObjects({
            orgId: organizationId
        })
            .then((result) => {
                // parse the string result
                const parsedData = JSON.parse(result);
                if (parsedData.errors.length > 0) {
                    parsedData.errors.forEach((error) => {
                        this.showToastMessage('Application Error', error, 'error', 'dismissable');
                    });
                    this.dispatchSpinnerEvent(true);
                }
                if (parsedData.options.length > 0) {
                    // populate orgObjects combobox values with the new response
                    this.orgObjects = parsedData.options;
                    this.showObjectInputAsPicklist = true;
                    this.dispatchSpinnerEvent(true);
                }
            })
            .catch((error) => {
                this.showToastMessage('Application Error', error, 'error', 'dismissable');
                this.dispatchSpinnerEvent(true);
            });
    }

    recordDMLOperations() {
        // Create the recordInput object
        const fields = {};
        fields[RECORD_ID.fieldApiName] = this.data[RECORD_ID.fieldApiName];
        fields[RECORD_NAME.fieldApiName] = this.data[RECORD_NAME.fieldApiName];
        fields[CONFIGURATION_SOURCE_ORG.fieldApiName] = this.data[CONFIGURATION_SOURCE_ORG.fieldApiName];
        fields[OBJECT.fieldApiName] = this.data[OBJECT.fieldApiName];
        fields[HASH_FORMULA.fieldApiName] = this.data[HASH_FORMULA.fieldApiName];
        fields[FIELD_1.fieldApiName] = this.data[FIELD_1.fieldApiName];
        fields[FIELD_2.fieldApiName] = this.data[FIELD_2.fieldApiName];
        fields[FIELD_3.fieldApiName] = this.data[FIELD_3.fieldApiName];

        // if record id is not empty, we will update the record, if record id is empty we will create a new record
        if (this.data[RECORD_ID.fieldApiName]) {
            const recordInput = { fields };
            this.updateRecordMatchingFormula(recordInput);
        } else {
            // checking if org and object selected before creating the record
            if (this.data[CONFIGURATION_SOURCE_ORG.fieldApiName] && this.data[OBJECT.fieldApiName]) {
                const recordInput = { apiName: RECORD_MATCHING_FORMULA.objectApiName, fields };
                this.createRecordMatchingFormula(recordInput);
            } else {
                this.showToastMessage('Warning!', 'Please select a Configuration Source Org and Object', 'warning', 'dismissable');
            }
        }
    }

    updateRecordMatchingFormula(recordInput) {
        updateRecord(recordInput)
            .then(() => {
                this.showToastMessage('Success', 'Record Matching Formula record has been updated', 'success', 'dismissable');
                // Display fresh data in the form
                return refreshApex(this.data);
            })
            .catch((error) => {
                this.showToastMessage('UNEXPECTED ERROR on Record Update', error.body.message, 'error', 'dismissable');
            });
    }

    createRecordMatchingFormula(recordInput) {
        createRecord(recordInput)
            .then((recordMatchingFormula) => {
                this.recordId = recordMatchingFormula.id;
                this.data[RECORD_ID.fieldApiName] = recordMatchingFormula.id;
                this.showToastMessage('Success', 'Record Matching Formula record has been created', 'success', 'dismissable');

                // dispatch event for parent lwc component, in order to update name of the record on the header lwc
                const selectedEvent = new CustomEvent('updaterecordmatchingname', {
                    detail: this.data.Name
                });
                this.dispatchEvent(selectedEvent);

                // to disable source org and object fields checkiong if conditions are met
                if (this.data[RECORD_ID.fieldApiName] && this.data[CONFIGURATION_SOURCE_ORG.fieldApiName]) {
                    this.disableSourceOrgInput = true;
                }
                if (this.data[RECORD_ID.fieldApiName] && this.data[OBJECT.fieldApiName]) {
                    this.disableObjectInput = true;
                    this.showObjectInputAsPicklist = false;
                }

                // Display fresh data in the form
                return refreshApex(this.data);
            })
            .catch((error) => {
                if (this.isDuplicateError(error)) {
                    this.showToastMessage(this.label.formulaErrorTitle, this.label.duplicateObjectErrorMessage, 'error', 'dismissable');
                } else {
                    this.showToastMessage('UNEXPECTED ERROR on Record Creation', error.body.message, 'error', 'dismissable');
                }
            });
    }

    isDuplicateError(error) {
        return (
            Array.isArray(error.body.output.errors) && error.body.output.errors.length && error.body.output.errors[0].errorCode === 'DUPLICATE_VALUE'
        );
    }
}