#!/usr/bin/env python3
import re
import argparse
import os


def parse_markdown_file(file_path):
    """Parse the markdown file and extract proxy information."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split the content into proxy entries
    proxy_entries = content.strip().split('\n\n')
    
    proxy_list = []
    for entry in proxy_entries:
        lines = entry.strip().split('\n')
        proxy_data = {}
        for line in lines:
            if ': ' in line:
                key, value = line.split(': ', 1)
                proxy_data[key] = value
        
        if 'Proxy' in proxy_data and proxy_data.get('Status') == 'working':
            proxy_list.append(proxy_data['Proxy'])
    
    return proxy_list


def main():
    parser = argparse.ArgumentParser(description='Extract proxies from Markdown file and save to TXT format')
    parser.add_argument('input_file', help='Input Markdown file path')
    parser.add_argument('output_file', help='Output TXT file path')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input_file):
        print(f"Error: Input file {args.input_file} does not exist")
        return
    
    # Parse the markdown file
    proxy_list = parse_markdown_file(args.input_file)
    
    # Write to output file
    with open(args.output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(proxy_list))
    
    print(f"Conversion complete! {len(proxy_list)} proxies written to {args.output_file}")


if __name__ == "__main__":
    main()
