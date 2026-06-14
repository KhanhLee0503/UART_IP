import re
import os

def align_port_or_logic(block):
    """
    Xử lý căn lề cho cả port (input/output logic) và biến nội bộ (logic)
    Chia làm 3 cột: [Keywords] [Range] [Name]
    """
    parts = []
    max_kw = 0    # Độ dài lớn nhất của "input logic" / "logic"
    max_range = 0 # Độ dài lớn nhất của "[31:0]"
    
    # Regex bóc tách: (input/output logic) ( [range] ) (tên_biến + dấu , hoặc ;)
    pattern = re.compile(r'^\s*(?P<kw>(?:input\s+|output\s+)?logic)\s+(?P<range>\[[^\]]+\])?\s*(?P<name>\w+.*)')

    for line in block:
        match = pattern.match(line)
        if match:
            kw = match.group('kw').strip()
            rg = match.group('range').strip() if match.group('range') else ""
            name = match.group('name').strip()
            
            max_kw = max(max_kw, len(kw))
            max_range = max(max_range, len(rg))
            parts.append((kw, rg, name))
        else:
            parts.append((line, None, None)) # Dòng không khớp regex (như comment)

    result = []
    for kw, rg, name in parts:
        if name is not None:
            # Căn lề: Keywords (padded) + Range (padded) + Name
            line_out = f"    {kw.ljust(max_kw)} {rg.ljust(max_range)} {name}"
            result.append(line_out.rstrip())
        else:
            result.append(kw) # Giữ nguyên nếu là comment hoặc dòng trống
    return result

def align_block_by_char(block, char):
    """Căn lề cho assign (=) và port mapping (()"""
    max_pos = 0
    parts = []
    for line in block:
        if char in line:
            left, right = line.split(char, 1)
            left = left.rstrip()
            max_pos = max(max_pos, len(left))
            parts.append((left, right.lstrip()))
        else:
            parts.append((line, None))
    return [f"{l.ljust(max_pos)} {char} {r}" if r is not None else l for l, r in parts]

def align_sv_code(code):
    lines = code.split('\n')
    output = []
    i = 0
    while i < len(lines):
        line = lines[i]
        line_strip = line.strip()

        # 1. Nhóm Port & Logic (Bắt đầu bằng input, output, hoặc logic)
        if line_strip.startswith(('input logic', 'output logic', 'logic ')):
            block = []
            while i < len(lines) and (lines[i].strip().startswith(('input logic', 'output logic', 'logic ')) or lines[i].strip().startswith('//')):
                block.append(lines[i]); i += 1
            output.extend(align_port_or_logic(block))
        
        # 2. Nhóm assign
        elif line_strip.startswith('assign '):
            block = []
            while i < len(lines) and lines[i].strip().startswith('assign '):
                block.append(lines[i]); i += 1
            output.extend(align_block_by_char(block, '='))
            
        # 3. Nhóm Port Mapping trong Instance (Bắt đầu bằng dấu .)
        elif line_strip.startswith('.'):
            block = []
            while i < len(lines) and (lines[i].strip().startswith('.') or lines[i].strip() == ''):
                if lines[i].strip() != '': block.append(lines[i])
                i += 1
            output.extend(align_block_by_char(block, '('))
        
        else:
            output.append(line); i += 1
            
    return '\n'.join(output)

def main():
    input_file = input("Nhap ten file muon align: ").strip()
    if not os.path.exists(input_file):
        print(f"❌ Không tìm thấy file '{input_file}'")
        return

    name, ext = os.path.splitext(input_file)
    output_file = f"{name}_aligned{ext}"

    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    aligned_content = align_sv_code(content)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(aligned_content)

    print(f"✅ Đã xuất file: {output_file}")

if __name__ == "__main__":
    main()