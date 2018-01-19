from snippet_helpers import *

def ex_module_name(path, snip):
    path = path_as_module_path(path)
    path = path_without_extension(path)
    snip.rv = path_as_module_name(path, separator=".")
