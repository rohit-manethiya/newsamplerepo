/*
 * MultiselectController synchronizes the values of the hidden elements to the
 * SelectOption lists.
 */
public with sharing class MultiselectController {
    public List<List<SelectOption>> leftOptionsOuterList {
        get {
            if (null == leftOptionsOuterList) {
                leftOptionsOuterList = new List<List<SelectOption>>();
            }
            return leftOptionsOuterList;
        }
        set;
    }
    // SelectOption lists for public consumption
    public SelectOption[] leftOptions {
        get;
        set {
            leftOptionsOuterList = new List<List<SelectOption>>();
            Integer listIndex = 0, iterationIndex = 0;
            leftOptionsOuterList.add(new List<SelectOption>());
            if (null == value) {
                value = new List<SelectOption>();
            }
            for (SelectOption soItem : value) {
                if (iterationIndex == 1000) {
                    leftOptionsOuterList.add(new List<SelectOption>());
                    listIndex++;
                    iterationIndex = 0;
                }
                leftOptionsOuterList[listIndex].add(soItem);
                iterationIndex++;
            }
            leftOptions = leftOptionsOuterList[0];
        }
    }
    public SelectOption[] rightOptions { get; set; }

    // Parse &-separated values and labels from value and
    // put them in option
    private List<SelectOption> parseOptions(String value) {
        List<SelectOption> options = new List<SelectOption>();
        String[] parts = value.split('&');
        for (Integer i = 0; i < parts.size() / 2; i++) {
            options.add(new SelectOption(EncodingUtil.urlDecode(parts[i * 2], 'UTF-8'), EncodingUtil.urlDecode(parts[(i * 2) + 1], 'UTF-8')));
        }
        return options;
    }

    // Backing for hidden text field containing the options from the
    // left list
    public String leftOptionsHidden {
        get;
        set {
            leftOptionsHidden = value;
            leftOptions = parseOptions(value);
        }
    }

    // Backing for hidden text field containing the options from the
    // right list
    public String rightOptionsHidden {
        get;
        set {
            rightOptionsHidden = value;
            rightOptions = parseOptions(value);
        }
    }
}