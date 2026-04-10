import os
import re

lib_dir = "d:\\Flutter_project\\mamark\\lib"

def process_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    original_content = content

    # Replace import
    content = content.replace("import 'package:go_router/go_router.dart';", "import 'package:get/get.dart';")

    # Replace context.pushNamed('foo') with Get.toNamed('foo')
    content = re.sub(r"context\.pushNamed\(([^)]+)\)", r"Get.toNamed(\1)", content)

    # Replace context.push('/foo', extra: bar) with Get.toNamed('/foo', arguments: bar)
    def push_extra_replacer(match):
        route = match.group(1)
        extra = match.group(2)
        return f"Get.toNamed({route}, arguments: {extra})"
    
    content = re.sub(r"context\.push\(([^,]+),\s*extra:\s*([^)]+)\)", push_extra_replacer, content)

    # Replace standard context.push('/foo')
    content = re.sub(r"context\.push\(([^)]+)\)", r"Get.toNamed(\1)", content)

    # Replace context.go('/foo') -> Get.offAllNamed('/foo')
    content = re.sub(r"context\.go\(([^)]+)\)", r"Get.offAllNamed(\1)", content)
    
    # Replace context.pop() -> Get.back()
    content = re.sub(r"context\.pop\(\)", "Get.back()", content)

    if content != original_content:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            process_file(os.path.join(root, file))

print("Done.")
