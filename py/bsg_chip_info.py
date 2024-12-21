
import uhdm

_UHDM_MODULE_PREFIX = "work@"

def uhdm_test_generator(it_type, data):
    vpi_iterator = uhdm.vpi_iterate(it_type, data)
    yield from iter(lambda: uhdm.vpi_scan(vpi_iterator), None)


def parse():
    s = uhdm.Serializer()
    data = s.Restore('slpp_unit/surelog.uhdm')

    design = {}
    design["modules"] = []
    design["top"] = []

    module_iterator = uhdm.vpi_iterate(uhdm.uhdmtopModules,data[0])
    while True:
        vpiObj_module = uhdm.vpi_scan(module_iterator)
        if vpiObj_module is None:
            break
        vpiObj_defname = uhdm.vpi_get_str(uhdm.vpiDefName,vpiObj_module)
        if "__abstract" in vpiObj_defname:
            continue
        stripped_name = vpiObj_defname.replace(_UHDM_MODULE_PREFIX,"")
        design["top"] = stripped_name

    module_iterator = uhdm.vpi_iterate(uhdm.uhdmallModules,data[0])
    while True:
        vpiObj_module = uhdm.vpi_scan(module_iterator)
        if vpiObj_module is None:
            break
        vpiObj_defname = uhdm.vpi_get_str(uhdm.vpiDefName,vpiObj_module)
        if "__abstract" in vpiObj_defname:
            continue
        if design["top"] == vpiObj_defname:
            continue
        stripped_name = vpiObj_defname.replace(_UHDM_MODULE_PREFIX,"")
        design["modules"].append(stripped_name)


    module_iterator = uhdm.vpi_iterate(uhdm.uhdmtopModules,data[0])
    while True:
        vpiObj_module = uhdm.vpi_scan(module_iterator)

        sub_iterator = uhdm.vpi_iterate(uhdm.mod_handle, vpiObj_module)
        while True:
            vpiSub_module = uhdm.vpi_scan(sub_iterator)
            if vpiSub_module is None:
                break
            vpiObj_defname = uhdm.vpi_get_str(uhdm.vpiDefName,vpiObj_module)
            print(f"DEF: {vpiObj_defname}")
        
        

    #import pprint
    #pprint.pprint(design)

def hier(data):
    s = uhdm.Serializer()

    print("VERSION 1")
    module_iterator = uhdm.vpi_iterate(uhdm.uhdmtopModules, data)
    while True:
        vpiObj_module = uhdm.vpi_scan(module_iterator)
        if vpiObj_module is None:
            break
        vpiObj_defname = uhdm.vpi_get_str(uhdm.vpiDefName, vpiObj_module)
        print(vpiObj_defname)
    for vpiObj_module in uhdm_test_generator(uhdm.uhdmtopModules, data):
        vpiObj_defname = uhdm.vpi_get_str(uhdm.vpiDefName, vpiObj_module)
        print(vpiObj_defname)
    print("VERSION 2")


if __name__ == "__main__":
    s = uhdm.Serializer()
    data = s.Restore('slpp_unit/surelog.uhdm')
    #parse(data[0])
    hier(data[0])

