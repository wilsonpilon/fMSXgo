import os
import re

# File paths
Z80_C_PATH = os.path.join(os.path.dirname(__file__), "fMSX", "Z80", "Z80.c")
TABLES_H_PATH = os.path.join(os.path.dirname(__file__), "fMSX", "Z80", "Tables.h")

# 1. Parse Enums from Z80.c
with open(Z80_C_PATH, "r", encoding="utf-8") as f:
    z80_c_content = f.read()

def get_enum_map(enum_name):
    # Find enum block
    pattern = r'enum\s+' + enum_name + r'\s*\{([^}]+)\}'
    match = re.search(pattern, z80_c_content)
    if not match:
        raise ValueError(f"Could not find enum {enum_name} in Z80.c")
    # Split by comma and clean up comments/whitespace
    raw_items = match.group(1)
    # Remove single-line comments
    raw_items = re.sub(r'//.*', '', raw_items)
    # Remove multi-line comments
    raw_items = re.sub(r'/\*.*?\*/', '', raw_items, flags=re.DOTALL)
    items = [x.strip() for x in raw_items.split(',')]
    items = [x for x in items if x]
    return {name: idx for idx, name in enumerate(items)}

codes_map = get_enum_map("Codes")
codes_cb_map = get_enum_map("CodesCB")
codes_ed_map = get_enum_map("CodesED")

print(f"Parsed {len(codes_map)} Codes, {len(codes_cb_map)} CodesCB, {len(codes_ed_map)} CodesED.")

# 2. Parse Tables from Tables.h and generate Z80_Tables.pbi
with open(TABLES_H_PATH, "r", encoding="utf-8") as f:
    tables_h_content = f.read()

constant_map = {
    'S_FLAG': 0x80,
    'Z_FLAG': 0x40,
    'H_FLAG': 0x10,
    'P_FLAG': 0x04,
    'V_FLAG': 0x04,
    'N_FLAG': 0x02,
    'C_FLAG': 0x01,
}

# Helper to extract array elements
def extract_table(table_name, size):
    pattern = r'(?:byte|word)\s+' + table_name + r'\[\d+\]\s*=\s*\{([^}]+)\}'
    match = re.search(pattern, tables_h_content, re.DOTALL)
    if not match:
        raise ValueError(f"Could not find table {table_name} in Tables.h")
    raw_data = match.group(1)
    
    # Split by comma and evaluate
    raw_vals = [x.strip() for x in raw_data.split(',')]
    resolved_vals = []
    for rv in raw_vals:
        expr = rv
        # Remove comments
        expr = re.sub(r'//.*', '', expr)
        expr = re.sub(r'/\*.*?\*/', '', expr, flags=re.DOTALL)
        expr = expr.strip()
        if not expr:
            continue
        # Replace constants
        for name, val in constant_map.items():
            expr = re.sub(r'\b' + name + r'\b', str(val), expr)
        # Clean up double operators if any, then evaluate
        resolved_vals.append(eval(expr))
        
    if len(resolved_vals) != size:
        raise ValueError(f"Table {table_name} size mismatch: got {len(resolved_vals)}, expected {size}")
    return resolved_vals


cycles = extract_table("Cycles", 256)
cycles_cb = extract_table("CyclesCB", 256)
cycles_ed = extract_table("CyclesED", 256)
cycles_xx = extract_table("CyclesXX", 256)
cycles_xx_cb = extract_table("CyclesXXCB", 256)
zs_table = extract_table("ZSTable", 256)
pzs_table = extract_table("PZSTable", 256)
daa_table = extract_table("DAATable", 2048)

print("Tables parsed successfully.")

# Write Z80_Tables.pbi
with open(os.path.join(os.path.dirname(__file__), "Z80_Tables.pbi"), "w", encoding="utf-8") as f:
    f.write("; Z80 timing and flag lookup tables - Generated automatically\n\n")
    f.write("Global Dim Cycles.a(255)\n")
    f.write("Global Dim CyclesCB.a(255)\n")
    f.write("Global Dim CyclesED.a(255)\n")
    f.write("Global Dim CyclesXX.a(255)\n")
    f.write("Global Dim CyclesXXCB.a(255)\n")
    f.write("Global Dim ZSTable.a(255)\n")
    f.write("Global Dim PZSTable.a(255)\n")
    f.write("Global Dim DAATable.u(2047)\n\n")
    
    f.write("Procedure InitZ80Tables()\n")
    f.write("  Protected i.l\n")
    
    def write_array_init(array_name, data, datatype_suffix):
        f.write(f"  Restore Z80_{array_name}_Data\n")
        f.write(f"  For i = 0 To {len(data)-1}\n")
        f.write(f"    Read.{datatype_suffix} {array_name}(i)\n")
        f.write(f"  Next\n")
        
    write_array_init("Cycles", cycles, "a")
    write_array_init("CyclesCB", cycles_cb, "a")
    write_array_init("CyclesED", cycles_ed, "a")
    write_array_init("CyclesXX", cycles_xx, "a")
    write_array_init("CyclesXXCB", cycles_xx_cb, "a")
    write_array_init("ZSTable", zs_table, "a")
    write_array_init("PZSTable", pzs_table, "a")
    write_array_init("DAATable", daa_table, "u")
    
    f.write("EndProcedure\n\n")
    
    # Write DataSection
    f.write("DataSection\n")
    def write_datasection_block(array_name, data, data_type):
        f.write(f"  Z80_{array_name}_Data:\n")
        for idx in range(0, len(data), 16):
            chunk = data[idx:idx+16]
            data_str = ", ".join(f"${x:X}" for x in chunk)
            f.write(f"    Data.{data_type} {data_str}\n")
            
    write_datasection_block("Cycles", cycles, "a")
    write_datasection_block("CyclesCB", cycles_cb, "a")
    write_datasection_block("CyclesED", cycles_ed, "a")
    write_datasection_block("CyclesXX", cycles_xx, "a")
    write_datasection_block("CyclesXXCB", cycles_xx_cb, "a")
    write_datasection_block("ZSTable", zs_table, "a")
    write_datasection_block("PZSTable", pzs_table, "a")
    write_datasection_block("DAATable", daa_table, "u")
    f.write("EndDataSection\n")

print("Z80_Tables.pbi generated.")

# 3. Translate Opcode includes
def clean_c_line(line):
    # Strip comments if they are whole line
    trimmed = line.strip()
    if trimmed.startswith("/*") and trimmed.endswith("*/"):
        return ""
    # Strip break; at end of case lines
    line = re.sub(r'\s*break\s*;\s*$', '', line)
    return line

def replace_c_ifs(content):
    pos = 0
    while True:
        match = re.search(r'\bif\s*\(', content[pos:])
        if not match:
            break
        
        start_idx = pos + match.start()
        open_paren_idx = start_idx + len(match.group(0)) - 1
        
        nest = 1
        end_paren_idx = -1
        for idx in range(open_paren_idx + 1, len(content)):
            if content[idx] == '(':
                nest += 1
            elif content[idx] == ')':
                nest -= 1
                if nest == 0:
                    end_paren_idx = idx
                    break
        if end_paren_idx == -1:
            pos = open_paren_idx + 1
            continue
            
        condition = content[open_paren_idx + 1 : end_paren_idx].strip()
        
        rest = content[end_paren_idx + 1 :]
        rest_stripped = rest.strip()
        
        if rest_stripped.startswith('{'):
            brace_start = end_paren_idx + 1 + rest.find('{')
            nest_brace = 1
            end_brace_idx = -1
            for idx in range(brace_start + 1, len(content)):
                if content[idx] == '{':
                    nest_brace += 1
                elif content[idx] == '}':
                    nest_brace -= 1
                    if nest_brace == 0:
                        end_brace_idx = idx
                        break
            if end_brace_idx != -1:
                block_body = content[brace_start + 1 : end_brace_idx].strip()
                after_block = content[end_brace_idx + 1 :].strip()
                if after_block.startswith("else"):
                    else_rest = after_block[4:].strip()
                    if else_rest.startswith('{'):
                        else_brace_start = end_brace_idx + 1 + content[end_brace_idx + 1 :].find('else') + 4
                        else_brace_start = else_brace_start + content[else_brace_start:].find('{')
                        nest_else_brace = 1
                        end_else_brace_idx = -1
                        for idx in range(else_brace_start + 1, len(content)):
                            if content[idx] == '{':
                                nest_else_brace += 1
                            elif content[idx] == '}':
                                nest_else_brace -= 1
                                if nest_else_brace == 0:
                                    end_else_brace_idx = idx
                                    break
                        if end_else_brace_idx != -1:
                            else_body = content[else_brace_start + 1 : end_else_brace_idx].strip()
                            replacement = f"If {condition} : {block_body} : Else : {else_body} : EndIf"
                            content = content[:start_idx] + replacement + content[end_else_brace_idx + 1 :]
                            pos = start_idx + len(replacement)
                            continue
                    else:
                        else_stmt_start = end_brace_idx + 1 + content[end_brace_idx + 1 :].find('else') + 4
                        else_semi = else_stmt_start + content[else_stmt_start:].find(';')
                        else_body = content[else_stmt_start : else_semi].strip()
                        replacement = f"If {condition} : {block_body} : Else : {else_body} : EndIf"
                        content = content[:start_idx] + replacement + content[else_semi + 1 :]
                        pos = start_idx + len(replacement)
                        continue
                else:
                    replacement = f"If {condition} : {block_body} : EndIf"
                    content = content[:start_idx] + replacement + content[end_brace_idx + 1 :]
                    pos = start_idx + len(replacement)
                    continue
        else:
            semi_idx = end_paren_idx + 1 + rest.find(';')
            stmt_body = content[end_paren_idx + 1 : semi_idx].strip()
            after_stmt = content[semi_idx + 1 :].strip()
            if after_stmt.startswith("else"):
                else_rest = after_stmt[4:].strip()
                if else_rest.startswith('{'):
                    else_brace_start = semi_idx + 1 + content[semi_idx + 1 :].find('else') + 4
                    else_brace_start = else_brace_start + content[else_brace_start:].find('{')
                    nest_else_brace = 1
                    end_else_brace_idx = -1
                    for idx in range(else_brace_start + 1, len(content)):
                        if content[idx] == '{':
                            nest_else_brace += 1
                        elif content[idx] == '}':
                            nest_else_brace -= 1
                            if nest_else_brace == 0:
                                    end_else_brace_idx = idx
                                    break
                    if end_else_brace_idx != -1:
                        else_body = content[else_brace_start + 1 : end_else_brace_idx].strip()
                        replacement = f"If {condition} : {stmt_body} : Else : {else_body} : EndIf"
                        content = content[:start_idx] + replacement + content[end_else_brace_idx + 1 :]
                        pos = start_idx + len(replacement)
                        continue
                else:
                    else_stmt_start = semi_idx + 1 + content[semi_idx + 1 :].find('else') + 4
                    else_semi = else_stmt_start + content[else_stmt_start:].find(';')
                    else_body = content[else_stmt_start : else_semi].strip()
                    replacement = f"If {condition} : {stmt_body} : Else : {else_body} : EndIf"
                    content = content[:start_idx] + replacement + content[else_semi + 1 :]
                    pos = start_idx + len(replacement)
                    continue
            else:
                replacement = f"If {condition} : {stmt_body} : EndIf"
                content = content[:start_idx] + replacement + content[semi_idx + 1 :]
                pos = start_idx + len(replacement)
                continue
                
        pos = open_paren_idx + 1
    return content

def translate_c_code(code_str, enum_map):
    # Preprocess if-else patterns at file level
    code_str = replace_c_ifs(code_str)

    lines = code_str.split("\n")
    translated = []
    
    for line in lines:
        cleaned = clean_c_line(line)
        if not cleaned:
            continue
            
        # Replace standalone C increments/decrements (e.g. R->DE.W--;) with proper assignments
        cleaned = re.sub(r'\b(R->[A-Za-z0-9_]+\.(?:W|B\.[hl]))(\+\+|--);', lambda m: f"{m.group(1)} = {m.group(1)} {'+' if m.group(2)=='++' else '-'} 1;", cleaned)

        # Check for J.W++ or HL/DE post-increments/decrements in this line before pointer replacement
        had_j_inc = "J.W++" in cleaned or "J.W++" in line
        post_reg_inc = re.findall(r'(\b[A-Za-z0-9_]+->' + r'(?:HL|DE)\.W)(\+\+|--)', cleaned)
        
        post_reg_updates = []
        for reg_expr, op in post_reg_inc:
            pb_reg = reg_expr.replace("R->", "*R\\").replace(".", "\\")
            cleaned = cleaned.replace(reg_expr + op, pb_reg)
            op_char = "+" if op == "++" else "-"
            post_reg_updates.append(f"{pb_reg} {op_char} 1")
            
        if had_j_inc:
            cleaned = cleaned.replace("J.W++", "J\\W").replace("J\\W++", "J\\W")
            post_reg_updates.append("J\\W + 1")

        # Parse case statements: e.g. "case JR_NZ: ... "
        case_matches = re.findall(r'case\s+(\w+):', cleaned)
        if case_matches:
            case_vals = []
            for c in case_matches:
                if c in enum_map:
                    case_vals.append(f"${enum_map[c]:02X}")
                else:
                    pfx_map = {"PFX_CB": "$CB", "PFX_ED": "$ED", "PFX_FD": "$FD", "PFX_DD": "$DD"}
                    if c in pfx_map:
                        case_vals.append(pfx_map[c])
                    else:
                        if c.startswith("0x") or c.isdigit():
                            case_vals.append(c.replace("0x", "$"))
                        else:
                            print(f"Warning: Unknown case: {c}")
                            case_vals.append(c)
            cleaned = re.sub(r'case\s+\w+:\s*', '', cleaned)
            cleaned = "Case " + ", ".join(case_vals) + " : " + cleaned

        # Replace default:
        cleaned = re.sub(r'\bdefault\s*:', 'Default :', cleaned)

        # Pre-decrement/increment inside If statement
        # e.g., If !--R->BC.B.h -> *R\BC\B\h - 1 : If Not *R\BC\B\h
        cleaned = re.sub(
            r'\bIf\s+!\s*(--|\+\+)([A-Za-z0-9_]+->[A-Za-z0-9_]+(?:\.B\.[hl]|\.W))',
            lambda m: f"{m.group(2).replace('R->', '*R\\').replace('.', '\\')} {'+' if m.group(1)=='++' else '-'} 1 : If Not {m.group(2).replace('R->', '*R\\').replace('.', '\\')}",
            cleaned
        )
        # e.g., If --R->BC.B.h -> *R\BC\B\h - 1 : If *R\BC\B\h
        cleaned = re.sub(
            r'\bIf\s+(--|\+\+)([A-Za-z0-9_]+->[A-Za-z0-9_]+(?:\.B\.[hl]|\.W))',
            lambda m: f"{m.group(2).replace('R->', '*R\\').replace('.', '\\')} {'+' if m.group(1)=='++' else '-'} 1 : If {m.group(2).replace('R->', '*R\\').replace('.', '\\')}",
            cleaned
        )
        # Also handles if(--R->BC.W) without pointer explicitly in case it didn't match:
        cleaned = re.sub(
            r'\bIf\s+(--|\+\+)([A-Za-z0-9_]+\.W)',
            lambda m: f"{m.group(2).replace('.', '\\')} {'+' if m.group(1)=='++' else '-'} 1 : If {m.group(2).replace('.', '\\')}",
            cleaned
        )

        cleaned = cleaned.replace("RdZ80(", "SafeRdZ80(")

        # Convert (offset)OpZ80(...) to SignExtend8(ReadOp(*R)) or similar
        cleaned = cleaned.replace("(offset)OpZ80(R->PC.W++)", "SignExtend8(ReadOp(*R))")
        cleaned = cleaned.replace("(offset)OpZ80(R->PC.W)", "SignExtend8(SafeRdZ80(*R\\PC\\W))")
        cleaned = cleaned.replace("(offset)SafeRdZ80(R->PC.W)", "SignExtend8(SafeRdZ80(*R\\PC\\W))")

        # 1. Functions & Opcode reads
        cleaned = cleaned.replace("OpZ80(R->PC.W++)", "ReadOp(*R)")
        cleaned = cleaned.replace("OpZ80(R->SP.W++)", "ReadPop(*R)")
        cleaned = cleaned.replace("OpZ80(R->PC.W)", "SafeRdZ80(*R\\PC\\W)")
        cleaned = cleaned.replace("SafeRdZ80(R->HL.W)", "SafeRdZ80(*R\\HL\\W)")
        
        # Increments / Decrements
        cleaned = cleaned.replace("R->PC.W++", "*R\\PC\\W + 1")
        cleaned = cleaned.replace("R->SP.W++", "*R\\SP\\W + 1")
        cleaned = cleaned.replace("R->PC.W--", "*R\\PC\\W - 1")
        cleaned = cleaned.replace("R->SP.W--", "*R\\SP\\W - 1")
        
        cleaned = cleaned.replace("R->PC.W+=", "*R\\PC\\W + ")
        cleaned = cleaned.replace("R->PC.W-=", "*R\\PC\\W - ")
        cleaned = cleaned.replace("R->SP.W+=", "*R\\SP\\W + ")
        cleaned = cleaned.replace("R->SP.W-=", "*R\\SP\\W - ")

        # Z80 Structure Register Pair pointer replacements
        for reg in ["AF", "BC", "DE", "HL", "IX", "IY", "PC", "SP", "AF1", "BC1", "DE1", "HL1", "XX"]:
            cleaned = cleaned.replace(f"R->{reg}.B.l", f"*R\\{reg}\\B\\l")
            cleaned = cleaned.replace(f"R->{reg}.B.h", f"*R\\{reg}\\B\\h")
            cleaned = cleaned.replace(f"R->{reg}.W", f"*R\\{reg}\\W")

        # Other fields
        cleaned = cleaned.replace("R->IFF", "*R\\IFF")
        cleaned = cleaned.replace("R->I", "*R\\I")
        cleaned = cleaned.replace("R->R", "*R\\R")
        cleaned = cleaned.replace("R->ICount", "*R\\ICount")
        cleaned = cleaned.replace("R->IPeriod", "*R\\IPeriod")
        cleaned = cleaned.replace("R->IRequest", "*R\\IRequest")
        cleaned = cleaned.replace("R->IAutoReset", "*R\\IAutoReset")
        cleaned = cleaned.replace("R->TrapBadOps", "*R\\TrapBadOps")
        cleaned = cleaned.replace("R->Trap", "*R\\Trap")
        cleaned = cleaned.replace("R->Trace", "*R\\Trace")
        cleaned = cleaned.replace("R->User", "*R\\User")
        cleaned = cleaned.replace("R->IBackup", "*R\\IBackup")

        # Temporary union registers J
        cleaned = cleaned.replace("J.B.l", "J\\B\\l")
        cleaned = cleaned.replace("J.B.h", "J\\B\\h")
        cleaned = cleaned.replace("J.W", "J\\W")

        # Replace standalone pre-increments/decrements, e.g. --*R\BC\B\h
        cleaned = re.sub(
            r'(--|\+\+)(\*R\\\w+(?:\\B\\[hl]|\\W))',
            lambda m: f"{m.group(2)} {'+' if m.group(1)=='++' else '-'} 1",
            cleaned
        )

        # Replace standalone post-increments/decrements, e.g. *R\BC\W-- or XX\W++
        cleaned = re.sub(
            r'(\*R\\\w+(?:\\B\\[hl]|\\W)|XX\\W|XX\\B\\[hl])(\+\+|--)_?',
            lambda m: f"{m.group(1)} {'+' if m.group(2)=='++' else '-'} 1",
            cleaned
        )
        
        # Cleanup any remaining standalone ++ or -- that didn't match the pointer prefix yet
        cleaned = re.sub(
            r'(\b\w+)(\+\+|--)',
            lambda m: f"{m.group(1)} {'+' if m.group(2)=='++' else '-'} 1",
            cleaned
        )


        # Operators & Ternaries
        cleaned = cleaned.replace("&&", " And ")
        cleaned = cleaned.replace("||", " Or ")
        cleaned = cleaned.replace("!=", " <> ")
        cleaned = cleaned.replace("!", " Not ")

        # Ternary Operators translation:
        cleaned = re.sub(r'([^()?=;,\n]+)\s*\?\s*([^:;,\n]+)\s*:\s*0', r'(Bool(\1) * (\2))', cleaned)
        cleaned = re.sub(r'([^()?=;,\n]+)\s*\?\s*0\s*:\s*([^:;,\n]+)', r'(Bool(\1 = 0) * (\2))', cleaned)

        # In-place assignment operators translation (+=, -=, &=, |=, ^=) with proper assignments
        cleaned = re.sub(r'(\*?[A-Za-z0-9_\\\\]+)\s*([\+\-\&\|\^])=\s*([^;:\n]+)', lambda m: m.group(1) + " = " + m.group(1) + " " + (m.group(2) if m.group(2) != '^' else '!') + " " + m.group(3), cleaned)
        
        # Remaining bitwise XOR
        cleaned = cleaned.replace("^", "!")
        

        
        # Replace array square brackets with parentheses
        for tbl in ["Cycles", "CyclesCB", "CyclesED", "CyclesXX", "CyclesXXCB", "ZSTable", "PZSTable", "DAATable"]:
            cleaned = re.sub(tbl + r'\[([^\]]+)\]', tbl + r'(\1)', cleaned)
            
        # Convert C constants to PureBasic constants (prefix with #)
        for const in ["C_FLAG", "Z_FLAG", "S_FLAG", "H_FLAG", "P_FLAG", "V_FLAG", "N_FLAG",
                      "INT_NMI", "INT_NONE", "INT_QUIT", "IFF_2", "IFF_1", "IFF_IM1", "IFF_IM2", "IFF_EI", "IFF_HALT"]:
            cleaned = re.sub(r'\b' + const + r'\b', '#' + const, cleaned)
        
        cleaned = cleaned.replace("(offset)", "SignExtend8")
        cleaned = cleaned.replace("(byte)", "")
        cleaned = cleaned.replace("(word)", "")
        cleaned = cleaned.replace("(long)", "")
        
        # Replace standalone PatchZ80(R) and similar
        cleaned = re.sub(r'\bPatchZ80\s*\(\s*R\s*\)', 'PatchZ80(*R)', cleaned)
        cleaned = cleaned.replace("printf", "DebugPrint")
        
        # Format C hex numbers
        cleaned = re.sub(r'\b0x([0-9a-fA-F]+)\b', r'$\1', cleaned)

        # Semicolons
        cleaned = cleaned.replace(";", " : ")
        cleaned = re.sub(r':\s*:\s*', ': ', cleaned)
        cleaned = re.sub(r':\s*$', '', cleaned)
        
        if post_reg_updates:
            cleaned = cleaned + " : " + " : ".join(post_reg_updates)
            
        translated.append(cleaned)
        
    return "\n".join(translated)

# Translate and save the files
def process_file(src_name, dest_name, enum_map):
    src_path = os.path.join(os.path.dirname(__file__), "fMSX", "Z80", src_name)
    dest_path = os.path.join(os.path.dirname(__file__), dest_name)
    
    with open(src_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Preprocess: strip block and line comments to avoid confusion during parsing
    content = re.sub(r'/\*.*?\*/', ' ', content, flags=re.DOTALL)
    content = re.sub(r'//.*', '\n', content)
    
    # Strip multiline printf statements and replace with basic Debug statement
    content = re.sub(r'\bprintf\s*\(\s*".*?"\s*,\s*.*?\s*\);', 'Debug "Unrecognized instruction";', content, flags=re.DOTALL)
    
    # Split multiple C cases on the same line by inserting a newline after break;
    content = re.sub(r'\bbreak\s*;', 'break;\n', content)
    
    # Merge C lines ending with operators or other continuation characters
    raw_lines = content.split("\n")
    merged_lines = []
    current_line = ""
    for r_line in raw_lines:
        if not r_line.strip():
            continue
        combined = (current_line + " " + r_line).strip()
        if combined.endswith(("|", "&", "+", "-", "=", ",", "(", "?", ":", "||", "&&", "^", "\\")):
            current_line = current_line + " " + r_line
        else:
            merged_lines.append(current_line + " " + r_line)
            current_line = ""
    if current_line:
        merged_lines.append(current_line)
    content = "\n".join(merged_lines)
    
    translated = translate_c_code(content, enum_map)
    
    with open(dest_path, "w", encoding="utf-8") as f:
        f.write(f"; Translated from {src_name} - Generated automatically\n\n")
        f.write(translated)
        f.write("\n")
        
    print(f"Processed {src_name} -> {dest_name}")

process_file("Codes.h", "Z80_Codes.pbi", codes_map)
process_file("CodesCB.h", "Z80_CodesCB.pbi", codes_cb_map)
process_file("CodesED.h", "Z80_CodesED.pbi", codes_ed_map)
process_file("CodesXX.h", "Z80_CodesXX.pbi", codes_map)
process_file("CodesXCB.h", "Z80_CodesXCB.pbi", codes_cb_map)

print("All translations completed.")
