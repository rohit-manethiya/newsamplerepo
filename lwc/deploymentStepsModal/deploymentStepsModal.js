import { LightningElement, api } from 'lwc'; // wire,
// import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

// import { showToastError } from 'c/copadocoreToastNotification';
import { autoFormValidation } from 'c/copadocoreUtils';

import Cancel from '@salesforce/label/c.Cancel';
import NEXT from '@salesforce/label/c.NEXT';
import SAVE from '@salesforce/label/c.Save';
import Add_New_Step from '@salesforce/label/c.Add_New_Step';
import Select_Step_Type from '@salesforce/label/c.Select_Step_Type';
import Edit_Step from '@salesforce/label/c.Edit_Step';

export default class DeploymentStepsModal extends LightningElement {
    label = {
        Cancel,
        NEXT,
        SAVE,
        Add_New_Step,
        Select_Step_Type,
        Edit_Step
    };

    @api currentDeploymentId;
    @api selectedStepId;
    @api selectedStepName;
    @api selectedStepType;

    stepTypes = [
        { label: 'Apex', value: 'Apex' },
        // { label: 'Automation', value: 'Automation' },
        { label: 'External CI', value: 'External CI' },
        { label: 'Salesforce Flow', value: 'Salesforce Flow' }
    ];

    _sizesByStepType = {
        'Apex': 'medium',
        // 'Automation': 'small',
        'External CI': 'small',
        'Salesforce Flow': 'medium'
    };
    get size() {
        if (!this.stepType) {
            return 'small';
        }
        return this._sizesByStepType[this.stepType];
    }

    _stepType;
    get stepType() {
        return this.selectedStepType || this._stepType;
    }

    get title() {
        if (this.isCreation) {
            return this._stepType ? this.label.Add_New_Step : this.label.Select_Step_Type;
        }
        return this.label.Edit_Step;
    }

    // If public property has not a provided value from the parent component
    // it means that the step is being created
    get isCreation() {
        return this.selectedStepId ? false : true;
    }

    // Commented until all types are available
    /*@wire(getObjectInfo, { objectApiName: STEP_OBJECT })
    stepInfo;

    get stepDefaultRecordTypeId() {
        return this.stepInfo.data.defaultRecordTypeId;
    }

    @wire(getPicklistValues, { recordTypeId: '$stepDefaultRecordTypeId', fieldApiName: TYPE_FIELD })
    wiredStepTypeValues(value) {
        const { data, error } = value;
        if (data) {
            this._stepTypes = data.values;
            this.error = undefined;
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            console.error(error);
            this._stepTypes = undefined;
        }
    }*/

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    handleCancel() {
        const details = this.template.querySelector('c-deployment-steps-details');

        if (details) {
            details.restoreOriginalValues();
        }

        this.handleRestoreOriginalValues();
    }

    handleNext() {
        const isFormValidated = autoFormValidation(this.template, this);

        if (isFormValidated) {
            this._stepType = this.template.querySelector('lightning-radio-group').value;
        }
    }

    handleSave() {
        const details = this.template.querySelector('c-deployment-steps-details');
        details.handleSave();
    }

    handleRefreshData() {
        this.dispatchEvent(new CustomEvent('refreshdata'));
    }

    handleRestoreOriginalValues() {
        this.hide();
        this._stepType = undefined;
        this.dispatchEvent(new CustomEvent('restoreoriginalvalues'));
    }
}