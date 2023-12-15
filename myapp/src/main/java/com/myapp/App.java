package com.myapp;

/**
 * Hello world!
 *
 */
public class App
{
    public static void main( String[] args )
    {
        String message = createMessage(args.length > 0 ? args[0] : null);
        System.out.println(message);
    }

    public static String createMessage(String name) {
        return String.format("Hello World! %s", name == null? "Anonymous": name);
    }

}
