import { showToastError } from 'c/copadocoreToastNotification';

// TODO: Move validation functions to other file ( validation )

/**
 * Automated form validation. Receives the component template (this.template), the context (this) and an optional object with options:
 *
 * Call example:
 *           utils.formValidation(this.template, this);
 *
 *           utils.formValidation(this.template, this, options);
 *
 *           options: {
 *               validationClass: 'myValidatorClass',
 *               validationMessage: 'my error message'
 *           }
 *
 * Returns true or false depending if the form is valid or not and triggers an error toast notification.
 */

const autoFormValidation = (form, context, options) => {
    if (!form || typeof form !== 'object') {
        console.error('Form validation. Template component is missed in validation');
        return false;
    }

    if (!context || typeof context !== 'object') {
        console.error('Form validation. Context is missed in validation');
        return false;
    }

    const validationClass = options && options.validationClass ? `.${options.validationClass}` : '.validValue';
    const validationMessage = options && options.validationMessage ? options.validationMessage : 'Please complete all required fields.';
    const formFields = form.querySelectorAll(validationClass);
    formFields.forEach((field) => {
        field.value = field.value ? field.value.trim() : field.value;
    });

    const allValid = [...form.querySelectorAll(validationClass)].reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
    }, true);

    const toastOptions = {
        message: validationMessage
    };

    if (!allValid) {
        showToastError(context, toastOptions);
    }

    return allValid ? true : false;
};

/**
 * Form validation. Receives the component template (this.template) and optionally the class used
 * for required form fields ( validValue as default)
 *
 * Call example:
 *           utils.formValidation(this.template);
 *           utils.formValidation(this.template, 'myValidatorClass');
 *
 * Returns true or false depending if the form is valid or not.
 */

const formValidation = (form, validClass) => {
    if (!form || typeof form !== 'object') {
        console.error('Form validation. Template component is missed in validation');
        return false;
    }

    const validationClass = validClass ? `.${validClass}` : '.validValue';
    const formFields = form.querySelectorAll(validationClass);
    formFields.forEach((field) => {
        field.value = field.value ? field.value.trim() : field.value;
    });
    const allValid = [...form.querySelectorAll(validationClass)].reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
    }, true);

    return allValid ? true : false;
};

/**
 * Checks if an object or array is empty.
 */
const isEmpty = (object) => {
    for (let key in object) {
        // eslint-disable-next-line no-prototype-builtins
        if (object.hasOwnProperty(key)) return false;
    }
    return true;
};

/**
 * Returns an array without duplicated values based on a propertyName.
 * @param {Array} array - Array or array of objects.
 * @param {string} propertyName - Property name to filter. If the array is simple don't send this parameter.
 */
const unique = (array, propertyName) => {
    let result;
    if (propertyName) {
        result = array.filter((e, i) => array.findIndex((a) => a[propertyName] === e[propertyName]) === i);
    } else {
        result = array.filter((a, b) => array.indexOf(a) === b);
    }
    return result;
};

/**
 * Clones an object or array.
 * @param {*} data - Object or Array to clone.
 */
const cloneData = (data) => {
    return JSON.parse(JSON.stringify(data));
};

/**
 * Gets an unique key.
 * @param {string} key - name to start the key with.
 */
const uniqueKey = (key) => {
    return `${key}_` + Math.random().toString(36).substr(2, 9);
};

/**
 * Gets Month, day, hour format from a number of hours.
 * @param {number} hours - number of hours.
 */
const getMonthDayHourFormat = (time) => {
    time = parseFloat(time);
    let formatted = '';
    let hours = Math.round(time),
        days = 0,
        months = 0;

    days = (hours / 24) | 0;
    hours -= days * 24;

    months = (days / 30) | 0;
    days -= months * 30;

    hours = Math.round(hours * 100) / 100;

    if (months > 0) {
        formatted = `${months}M `;
    }
    if (days > 0) {
        formatted += `${days}d `;
    }
    if (hours > 0) {
        formatted += `${hours}h`;
    }

    if (months === 0 && days === 0 && hours === 0) {
        formatted = `${hours}h`;
    }

    return formatted;
};

/**
 * Returns an async function wrapped to handle its possible errors
 * @param {function} asyncFunction - Async function to wrap. It should return a promise
 * @param {object} onErrorOptions - Toast options for the error notification if function fails
 */
const handleAsyncError = (asyncFunction, onErrorOptions) => (context, ...params) =>
    asyncFunction(context, ...params).catch((error) => {
        showToastError(
            context,
            Object.assign(onErrorOptions, {
                message: error.body ? error.body.message : error.message
            })
        );
        console.error(error);
    });

/**
 * Returns a function ready to be executed after the provided delay if it has not been called again in the meantime
 * @param {function} functionToDebounce - Function that will wait before being executed
 * @param {object} delay - Time that the function should wait before being executed
 * @warning this method sets the "_timeout" variable available for usage in the context from which this function is called,
 *          so that the context can use the variable at its own discretion to, for example, call the clearTimeout() method
 */
const getDebouncedFunction = (functionToDebounce, delay) => (context, ...params) => {
    clearTimeout(context._timeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    context._timeout = setTimeout(() => functionToDebounce.call(context, ...params), delay);
};

/**
 * Returns an empty promise, in order to force finishing the async operations pending in the call stack, playing with the event loop.
 */
// eslint-disable-next-line @lwc/lwc/no-async-operation
const flushPromises = async () => new Promise((resolve) => setTimeout(resolve, 0));

export {
    getDebouncedFunction,
    handleAsyncError,
    getMonthDayHourFormat,
    uniqueKey,
    cloneData,
    unique,
    isEmpty,
    formValidation,
    autoFormValidation,
    flushPromises
};