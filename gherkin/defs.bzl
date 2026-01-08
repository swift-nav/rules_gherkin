load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
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
    # Generate unique socket path based on TEST label, not steps label
    # This ensures each test gets its own socket for parallel execution
    test_label = ctx.label
    unique_socket = "/tmp/bazel_gherkin-{}-{}-{}.sock".format(
        ctx.workspace_name,
        test_label.package.replace("/", "_"),
        test_label.name,
    )

    # Create wire config with unique filename per test
    cucumber_wire_config = ctx.actions.declare_file("features/step_definitions/{}.wire".format(test_label.name))
    ctx.actions.write(cucumber_wire_config, "unix: " + unique_socket)

    support_for_wire = ctx.actions.declare_file("features/support/require_wire.rb")
    ctx.actions.write(support_for_wire, "require 'cucumber/wire'")

    # Get the executable from rb_binary (new rules_ruby produces FilesToRunProvider)
    cucumber_executable = ctx.attr._cucumber_ruby[DefaultInfo].files_to_run.executable

    feature_dir = "/".join([ctx.workspace_name, ctx.label.package])

    # Read the cucumber format from the build setting
    cucumber_format = ctx.attr._cucumber_format[BuildSettingInfo].value

    # Create unique output filename for test results (will be written to TEST_UNDECLARED_OUTPUTS_DIR)
    output_filename = "{}_output_{}.txt".format(test_label.name, cucumber_format)

    # Build cucumber args with format flag
    additional_cucumber_args = []
    additional_cucumber_args.append("--format={}".format(cucumber_format))
    additional_cucumber_args.append("--quiet")

    ctx.actions.expand_template(
        output = ctx.outputs.test,
        template = ctx.file._template,
        substitutions = {
            "{STEPS}": ctx.file.steps.short_path,
            "{CUCUMBER_RUBY}": cucumber_executable.short_path,
            "{FEATURE_DIR}": feature_dir,
            "{SOCKET}": unique_socket,
            "{ADDITIONAL_CUCUMBER_ARGS}": " ".join(additional_cucumber_args),
            "{OUTPUT_FILENAME}": output_filename,
        },
    )
    feature_specs = _get_transitive_srcs(None, ctx.attr.deps).to_list()
    feature_files = []
    for spec in feature_specs:
        spec_basename = spec.files.to_list()[0].basename
        f = ctx.actions.declare_file("features/" + spec_basename)
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
        "_cucumber_format": attr.label(
            doc = "The cucumber output format build setting",
            default = Label("@rules_gherkin//:cucumber_format"),
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

    # Merge runfiles from the cc_impl target
    runfiles = runfiles.merge(ctx.attr.cc_impl[DefaultInfo].default_runfiles)

    # Merge runfiles from data attribute
    for data_target in ctx.attr.data:
        runfiles = runfiles.merge(data_target[DefaultInfo].default_runfiles)

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
        "data": attr.label_list(
            doc = "Runtime data files required by the wire server",
            allow_files = True,
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
    data = attrs.get("data", [])

    cc_binary(
        name = binary_name,
        **attrs
    )
    _cc_gherkin_steps(
        name = name,
        cc_impl = ":" + binary_name,
        data = data,
        visibility = visibility,
    )
