//
//  BridgeModule.h
//

#ifndef BridgeModule_h
#define BridgeModule_h

#import <Foundation/Foundation.h>

NSArray<Class> *getBridgeModuleFactoryClasses(void);
void registerBridgeModuleFactoryClass(Class);

#define KRYSTAL_JS_BRIDGE_MODULE_FACTORY_CLASS(bridge_module_factory_name)                        \
    @interface _##bridge_module_factory_name : NSObject                                         \
    @end                                                                                        \
    @implementation _##bridge_module_factory_name : NSObject                                    \
    +(void)load                                                                                 \
    {                                                                                           \
        registerBridgeModuleFactoryClass([bridge_module_factory_name self]);                    \
    }                                                                                           \
    @end                                                                                        \


#endif /* BridgeModule_h */
