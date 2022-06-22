//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created by Daniele Margutti
//  Email: <hello@danielemargutti.com>
//  Web: <http://www.danielemargutti.com>
//
//  Copyright ©2022 Daniele Margutti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// `TableFormatter` is used to format log messages for console display.
/// Useful when you need to print complex data using tables rendered via console.
public class TableFormatter: EventFormatter {
    
    // MARK: - Public Properties
    
    /// Fields used to format the message part of the log.
    public var messageFields: [FieldsFormatter.Field] {
        set {
            self.messageFormatter.fields = newValue
        }
        get {
            self.messageFormatter.fields
        }
    }
    
    /// Separator used to compose the message and table fields.
    /// By default is set to `\n`.
    public var separator = "\n"
    
    /// Fields used to format the table's data.
    public var tableFields: [FieldsFormatter.Field]
    
    /// Column titles for table.
    public var columnHeaderTitles = (info: "ID", values: "VALUE")
    
    /// Maximum size of each column.
    public var maxColumnWidths = (info: 40, values: 100)
    
    /// How array and dictionaries (like `tags` and `extra` are encoded).
    /// The default's value is `queryString` but it may change depending
    /// by the formatter.
    public var structureFormatStyle: FieldsFormatter.StructureFormatStyle = .queryString
    
    // MARK: - Private Properties
    
    /// Formatter used to format the message part of the log.
    private var messageFormatter: FieldsFormatter
    
    // MARK: - Initialization
    
    /// Initialize a new table formatter.
    ///
    /// - Parameters:
    ///   - messageFields: fields to show in the first textual message outside the table.
    ///   - tableFields: table contents.
    public init(messageFields: [FieldsFormatter.Field],
                tableFields: [FieldsFormatter.Field]) {
        self.tableFields = tableFields
        self.messageFormatter = FieldsFormatter(fields: messageFields)
    }
    
    // MARK: - Compliance
    
    public func format(event: Event) -> SerializableData? {
        let message = messageFormatter.format(event: event)
        let table = formatTable(forEvent: event).stringValue
        let composed = ((message?.asString() ?? "") + separator + table)
        return composed
    }
    
    // MARK: - Private Functions
    
    open func formatTable(forEvent event: Event) -> Table {
        
        let columnIdentifier = Table.Column { col in
            col.footer = .init({ footer in
                footer.border = .boxDraw.heavyHorizontal
            })
            col.header = .init(title: self.columnHeaderTitles.info, { header in
                header.fillCharacter = " "
                header.topBorder = .boxDraw.heavyHorizontal
                header.trailingMargin = " \(Character.boxDraw.heavyVertical)"
                header.verticalPadding = .init({ padding in
                    padding.top = 0
                    padding.bottom = 0
                })
            })
            col.maxWidth = self.maxColumnWidths.info
            col.horizontalAlignment = .leading
            col.leadingMargin = "\(Character.boxDraw.heavyVertical) "
            col.trailingMargin = " \(Character.boxDraw.heavyVertical)"
        }
        
        
        let columnValues = Table.Column { col in
            col.footer = .init({ footer in
                footer.border = .boxDraw.heavyHorizontal
            })
            col.header = .init(title: self.columnHeaderTitles.values, { header in
                header.fillCharacter = " "
                header.leadingMargin = "\(Character.boxDraw.heavyVertical) "
                header.topBorder = .boxDraw.heavyHorizontal
                header.trailingMargin = " \(Character.boxDraw.heavyVertical)"
                header.verticalPadding = .init({ padding in
                    padding.top = 0
                    padding.bottom = 0
                })
            })
            col.maxWidth = self.maxColumnWidths.values
            col.horizontalAlignment = .leading
            col.leadingMargin = "\(Character.boxDraw.heavyVertical) "
            col.trailingMargin = " \(Character.boxDraw.heavyVertical)"
        }
        
        let cols = Table.Column.configureBorders(in: [columnIdentifier, columnValues], style: .light)
        let contents = valuesForEvent(event: event)
        
        let table: Table = Table(columns: cols, content: contents)
        return table
    }
    
    open func valuesForEvent(event: Event) -> [String] {
        var contents = [String]()
        
        for field in tableFields {
            guard let tableTitle = field.field.tableTitle,
                  let value = event.valueForFormatterField(field) else {
                continue
            }
            
            switch value {
            case let arrayValue as [String]:
                // Split each key in a custom row of the table
                guard let keys = field.field.keysToRetrive, keys.count == arrayValue.count else {
                    break
                }
                for index in 0..<keys.count {
                    contents.append(keys[index])
                    contents.append(postProcessValue(arrayValue[index], forField: field))
                }
                
            case let dictionaryValue as [String: Any]:
                // Split each key in a dictionary in a separate row
                for key in dictionaryValue.keys {
                    let value = dictionaryValue[key]
                    guard let value = value as? SerializableData else {
                        continue
                    }
                    
                    contents.append(key)
                    contents.append(postProcessValue(value.asString() ?? "", forField: field))
                }
                
            default:
                // Just report the row with value
                guard let stringifiedValue = structureFormatStyle.stringify(value, forField: field) else {
                    continue
                }
                
                contents.append(tableTitle)
                contents.append(postProcessValue(stringifiedValue, forField: field))
            }
        }
        
        return contents
    }
    
    private func postProcessValue(_ value: String, forField field: FieldsFormatter.Field) -> String {
        var stringifiedValue = value
        
        // Custom text transform
        for transform in field.transforms ?? [] {
            stringifiedValue = transform(stringifiedValue)
        }
        
        var stringValue = stringifiedValue.trunc(field.truncate).padded(field.padding)
        if let format = field.format {
            stringValue = String.format(format, value: stringValue)
        }
        
        return stringifiedValue
    }
    
}

extension FieldsFormatter.FieldIdentifier {
    
    fileprivate var tableTitle: String? {
        switch self {
        case .message: return "Message"
        case .callSite: return "Call site"
        case .callingThread: return "Thread"
        case .category: return "Category"
        case .eventUUID: return "UUID"
        case .subsystem: return "Subsystem"
        case .timestamp: return "Timestamp"
        case .level: return "Level"
        case .stackFrame: return "Stack Frame"
        case .processName: return "Process"
        case .processID: return "Process ID"
        case .userId: return "User ID"
        case .userEmail: return "User Email"
        case .username: return "User Name"
        case .ipAddress: return "IP"
        case .userData: return "User Data"
        case .fingerprint: return "Fingerprint"
        case .objectMetadata: return "Obj Metadata"
        case .object: return "Obj"
        case .delimiter: return nil
        case .literal(let title): return title
        case .tags: return "Tags"
        case .extra: return "Extra"
        case .custom: return nil
        }
    }
    
}

extension FieldsFormatter.FieldIdentifier {
    
    fileprivate var keysToRetrive: [String]? {
        switch self {
        case .userData(let keys): return keys
        case .objectMetadata(let keys): return keys
        case .tags(let keys): return keys
        case .extra(let keys): return keys
        default: return nil
        }
    }
    
}

protocol OptionalProtocol {
    func isSome() -> Bool
    func unwrap() -> Any
}

extension Optional : OptionalProtocol {
    func isSome() -> Bool {
        switch self {
        case .none: return false
        case .some: return true
        }
    }

    func unwrap() -> Any {
        switch self {
        case .none: preconditionFailure("trying to unwrap nil")
        case .some(let unwrapped): return unwrapped
        }
    }
}

func unwrapUsingProtocol<T>(_ any: T) -> Any
{
    guard let optional = any as? OptionalProtocol, optional.isSome() else {
        return any
    }
    return optional.unwrap()
}
