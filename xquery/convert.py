from pyexcel_xls import get_data
from lxml import etree
import re
import os
import datetime

# settings
input_folder = "inputs"
input_file = "Thematic_Lookups_v2_edited.xlsx"
output_name = "EPRTR-LCP"
# leave empty to transform all sheets
sheets_to_transform = ()
# leave empty to transform all columns
columns_to_transform = ()
columns_to_not_transform = ()
data_element_name = "row"


# init the xml file
input_file_data = get_data(afile=os.path.join(input_folder, input_file))

# check if the column from excel is needed
def node_is_needed(name):
    return (
       not columns_to_transform
       or name in columns_to_transform
       ) \
       and name not in columns_to_not_transform


def main():
    sheets = sheets_to_transform or input_file_data.keys()

    for sheet in sheets:
        document_node = etree.Element('dataroot')
        root = etree.ElementTree(document_node)

        # add 'generated' attribute to root element with current datetime
        current_date = str(
            datetime.datetime.now().replace(microsecond=0).isoformat()
        )
        document_node.set("generated", current_date)

        out_filename = "{}_{}.xml".format(output_name, sheet)
        output_file = os.path.join("outputs", out_filename)

        node_names = input_file_data[sheet][0]
        sheet_data_rows = input_file_data[sheet][1:]
        for row in sheet_data_rows:
            main_element = etree.SubElement(document_node, data_element_name)
            for index, node_value in enumerate(row):
                try:
                    node_name = node_names[index]
                except:
                    import pdb; pdb.set_trace()
                if node_is_needed(node_name):
                    node_name_normalized = re.sub(r'[\W\s]', '', node_name)
                    node = etree.SubElement(main_element, node_name_normalized)
                    # if isinstance(node_value, float):
                    #     node.text = "%.5f" % node_value
                    # else:
                    #     node.text = str(node_value)
                    node.text = str(node_value)

        root.write(output_file,
                   encoding=None,
                   method="xml",
                   pretty_print=True)


if __name__ == "__main__":
    main()