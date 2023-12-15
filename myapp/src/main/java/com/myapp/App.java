package com.myapp;

/**
 * Hello world!
 *
 */
public class App
{
    public static void main( String[] args )
    {
        String name = args.length > 0 ? args[0] : "Anonymous";
        System.out.printf("Hello World! %s", name);
    }
}
