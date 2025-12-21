load("@rules_cc//cc:defs.bzl", "cc_binary")

GherkinInfo = provider(
    "Gherkin info",
    fields = {
        "feature_specs": "The .feature files that make up a library",
    },
)

CucumberStepsInfo = provider(
    "Socket information to create a link between cucumber-ruby via the 'wire' server",
    fields = {
        "wire_socket": "The socket over which cucumber will communicate with the cc implemented 'wire' server",
    },
)

def _get_transitive_srcs(srcs, deps):
    """Obtain the source files for a target and its transitive dependencies.

    Args:
      srcs: a list of source files
      deps: a list of targets that are direct dependencies
    Returns:
      a collection of the transitive sources
    """
    return depset(
        srcs,
        transitive = [dep[GherkinInfo].feature_specs for dep in deps],
    )

def _gherkin_library(ctx):
    feature_specs = _get_transitive_srcs(ctx.attr.srcs, ctx.attr.deps)
    return [GherkinInfo(feature_specs = feature_specs)]

gherkin_library = rule(
    _gherkin_library,
    attrs = {
        "srcs": attr.label_list(
            doc = "Gherkin feature specifications",
            allow_files = [".feature"],
        ),
        "deps": attr.label_list(
            doc = "A list of other gherkin_library scenarios to include",
            providers = [GherkinInfo],
        ),
    },
    provides = [GherkinInfo],
)

def _gherkin_test(ctx):
    cucumber_wire_config = ctx.actions.declare_file("step_definitions/calculator_step.wire")
    wire_socket = ctx.attr.steps[CucumberStepsInfo].wire_socket
    ctx.actions.write(cucumber_wire_config, "unix: " + wire_socket)
    #ctx.actions.write(cucumber_wire_config, "host: 127.0.0.1" + "\n" + "port: 3902" + "\n")

    print("Wirefile: " + cucumber_wire_config.short_path)

    support_for_wire = ctx.actions.declare_file("support/require_wire.rb")
    ctx.actions.write(support_for_wire, 
"""
begin
  require 'cucumber/wire'
  puts "Wire gem is available"
rescue LoadError => e
  puts "Wire gem is not available: #{e.message}"
end
""")

    # Get the executable from rb_binary (new rules_ruby produces FilesToRunProvider)
    cucumber_executable = ctx.attr._cucumber_ruby[DefaultInfo].files_to_run.executable

    feature_dir = "/".join([ctx.workspace_name, "examples/Calc"]) # ctx.label.package
    print("Feature dir:  " + feature_dir)

    ctx.actions.expand_template(
        output = ctx.outputs.test,
        template = ctx.file._template,
        substitutions = {
            "{STEPS}": ctx.file.steps.short_path,
            "{CUCUMBER_RUBY}": cucumber_executable.short_path,
            "{FEATURE_DIR}": feature_dir,
        },
    )
    feature_specs = _get_transitive_srcs(None, ctx.attr.deps).to_list()
    feature_files = []
    for spec in feature_specs:
        spec_basename = spec.files.to_list()[0].basename
        f = ctx.actions.declare_file(spec_basename)
        feature_files.append(f)
        ctx.actions.symlink(output = f, target_file = spec.files.to_list()[0])

    runfiles = ctx.runfiles(files = [ctx.file.steps, cucumber_wire_config, support_for_wire] + feature_files)
    runfiles = runfiles.merge(ctx.attr.steps.default_runfiles)
    runfiles = runfiles.merge(ctx.attr._cucumber_ruby.default_runfiles)

    return [DefaultInfo(executable = ctx.outputs.test, runfiles = runfiles)]

gherkin_test = rule(
    _gherkin_test,
    attrs = {
        "deps": attr.label_list(
            doc = "A list of gherkin_library definitions",
            providers = [GherkinInfo],
        ),
        "steps": attr.label(
            doc = "The steps implementation to test the gherkin features against",
            providers = [CucumberStepsInfo],
            allow_single_file = True,
        ),
        "_template": attr.label(
            doc = "The template specification for the executable",
            default = Label("@rules_gherkin//gherkin:cc_gherkin_wire_test.sh.tpl"),
            allow_single_file = True,
        ),
        "_cucumber_ruby": attr.label(
            doc = "The path to cucumber ruby",
            default = Label("@rules_gherkin//:cucumber_ruby"),
            executable = True,
            cfg = "exec",
        ),
    },
    outputs = {"test": "%{name}.sh"},
    test = True,
)

def _cc_wire_gherkin_steps(ctx):
    label = ctx.label
    socket_path = "/tmp/bazel_gherkin-{}.sock".format(str(hash(label.package + label.name)))
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.steps_wire_server,
        substitutions = {
            "{SERVER}": ctx.file.cc_impl.short_path,
            "{SOCKET}": socket_path,
        },
    )
    runfiles = ctx.runfiles(files = [ctx.file.cc_impl])
    return [
        DefaultInfo(executable = ctx.outputs.steps_wire_server, runfiles = runfiles),
        CucumberStepsInfo(wire_socket = socket_path),
    ]

_cc_gherkin_steps = rule(
    _cc_wire_gherkin_steps,
    attrs = {
        "cc_impl": attr.label(
            doc = "The cc_binary target that hosts the cucumber 'wire' server",
            executable = True,
            cfg = "target",
            allow_single_file = True,
        ),
        "_template": attr.label(
            doc = "The template specification for the executable",
            default = Label("@rules_gherkin//gherkin:cc_gherkin_wire_steps.sh.tpl"),
            allow_single_file = True,
        ),
    },
    executable = True,
    outputs = {"steps_wire_server": "%{name}.sh"},
    provides = [DefaultInfo, CucumberStepsInfo],
)

def cc_gherkin_steps(**attrs):
    name = attrs.pop("name")
    binary_name = name + "_steps_binary"

    visibility = attrs.get("visibility", ["//visibility:private"])
    cc_binary(
        name = binary_name,
        **attrs
    )
    _cc_gherkin_steps(
        name = name,
        cc_impl = ":" + binary_name,
        visibility = visibility,
    )
